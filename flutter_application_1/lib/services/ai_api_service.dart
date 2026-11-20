import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'room_image_service.dart';

import '../models/ai_generation_job.dart';
import '../models/room_design_project.dart';

class AiApiException implements Exception {
  const AiApiException(this.message, {this.status, this.code});
  final String message;
  final int? status;
  final String? code;
  @override
  String toString() => message;
}

class AiApiService {
  AiApiService({http.Client? client, String? baseUrl, String? token})
    : _client = client ?? http.Client(),
      baseUrl = (baseUrl ?? const String.fromEnvironment('SANAA_API_URL'))
          .replaceAll(RegExp(r'/$'), ''),
      token = token ?? const String.fromEnvironment('SANAA_API_TOKEN');
  static final instance = AiApiService();
  final http.Client _client;
  final String baseUrl, token;
  bool get configured => baseUrl.isNotEmpty && token.isNotEmpty;
  Map<String, String> get headers => {'Authorization': 'Bearer $token'};
  Uri _uri(String path) {
    if (!configured) {
      throw const AiApiException(
        'AI сервер тохируулаагүй байна. Серверийн хаяг болон хандалтын түлхүүрийг тохируулна уу.',
      );
    }
    final uri = Uri.tryParse('$baseUrl$path');
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const AiApiException('Серверийн хаяг буруу байна.');
    }
    return uri;
  }

  Future<http.Response> _send(
    http.BaseRequest request, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    try {
      final response = await (() async => http.Response.fromStream(
        await _client.send(request),
      ))().timeout(timeout);
      if (response.statusCode >= 400) {
        String message =
            'Сервер хүсэлтийг гүйцэтгэсэнгүй (${response.statusCode}).';
        String? code;
        try {
          final error =
              (jsonDecode(utf8.decode(response.bodyBytes)) as Map)['error']
                  as Map?;
          message = error?['message'] as String? ?? message;
          code = error?['code'] as String?;
        } catch (_) {}
        throw AiApiException(message, status: response.statusCode, code: code);
      }
      return response;
    } on AiApiException {
      rethrow;
    } on TimeoutException {
      throw const AiApiException(
        'Серверийн хариу удаж байна. Холболтоо шалгаад дахин оролдоно уу.',
      );
    } catch (_) {
      throw const AiApiException(
        'AI сервертэй холбогдож чадсангүй. Хаяг болон сүлжээг шалгана уу.',
      );
    }
  }

  Future<Map<String, dynamic>> _json(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final request = http.Request(method, _uri(path))
      ..headers.addAll({...headers, 'Content-Type': 'application/json'});
    if (body != null) request.body = jsonEncode(body);
    final response = await _send(request);
    try {
      return Map<String, dynamic>.from(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map,
      );
    } catch (_) {
      throw const AiApiException('Сервер буруу хэлбэрийн хариу буцаалаа.');
    }
  }

  Future<Map<String, dynamic>> health() => _json('GET', '/health');
  Future<void> ensureUploaded(RoomDesignProject draft) async {
    if (draft.roomId != null) return;
    final request = http.MultipartRequest('POST', _uri('/api/rooms'))
      ..headers.addAll(headers)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          draft.sourceImage.bytes,
          filename: 'room.jpg',
        ),
      );
    final response = await _send(request);
    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    final image = json['image'] as Map;
    draft.roomId = json['room_id'] as String;
    draft.sourceImageId = image['id'] as String;
    draft.workingImageId = draft.sourceImageId;
    draft.width = image['width'] as int;
    draft.height = image['height'] as int;
  }

  Future<Uint8List> imageBytes(String id, {bool overlay = false}) async {
    final request = http.Request(
      'GET',
      _uri('/api/images/$id${overlay ? '?overlay=true' : ''}'),
    )..headers.addAll(headers);
    return (await _send(request)).bodyBytes;
  }

  Future<RoomImage> storedImage(String id) async =>
      _saveReceived(await imageBytes(id), id);

  Future<SelectedObjectMask> segment(
    RoomDesignProject draft, {
    List<double>? point,
    List<double>? box,
  }) async {
    await ensureUploaded(draft);
    final json = await _json('POST', '/api/segment', {
      'room_id': draft.roomId,
      'image_id': draft.workingImageId,
      'point': ?point,
      'box': ?box,
    });
    final id = json['id'] as String;
    return SelectedObjectMask(
      id: id,
      overlay: await imageBytes(id, overlay: true),
      manual: false,
    );
  }

  Future<SelectedObjectMask> uploadMask(
    RoomDesignProject draft,
    Uint8List png,
  ) async {
    await ensureUploaded(draft);
    final request = http.MultipartRequest('POST', _uri('/api/masks'))
      ..headers.addAll(headers)
      ..fields.addAll({
        'room_id': draft.roomId!,
        'image_id': draft.workingImageId!,
      })
      ..files.add(
        http.MultipartFile.fromBytes('file', png, filename: 'mask.png'),
      );
    final json =
        jsonDecode(utf8.decode((await _send(request)).bodyBytes)) as Map;
    final id = json['id'] as String;
    return SelectedObjectMask(
      id: id,
      overlay: await imageBytes(id, overlay: true),
      manual: true,
    );
  }

  Future<void> removeFurniture(RoomDesignProject draft) async {
    if (draft.masks.isEmpty) {
      throw const AiApiException('Арилгах хэсгээ сонгоно уу.');
    }
    final json = await _jsonLong('/api/remove-furniture', {
      'room_id': draft.roomId,
      'image_id': draft.workingImageId,
      'mask_ids': draft.masks.map((m) => m.id).toList(),
      'seed': draft.preferences.seed,
    });
    final id = json['id'] as String;
    final bytes = await imageBytes(id);
    draft.acceptedMaskIds.addAll(draft.masks.map((m) => m.id));
    draft.workingImageId = id;
    draft.workingImage = await _saveReceived(bytes, id);
    draft.masks.clear();
  }

  Future<Map<String, dynamic>> _jsonLong(
    String path,
    Map<String, dynamic> body,
  ) async {
    final request = http.Request('POST', _uri(path))
      ..headers.addAll({...headers, 'Content-Type': 'application/json'})
      ..body = jsonEncode(body);
    return Map<String, dynamic>.from(
      jsonDecode(
        utf8.decode(
          (await _send(
            request,
            timeout: const Duration(minutes: 15),
          )).bodyBytes,
        ),
      ) as Map,
    );
  }

  Future<AiGenerationJob> generate(RoomDesignProject draft) async {
    await ensureUploaded(draft);
    final result = await _json('POST', '/api/generate', {
      ...draft.preferences.toJson(),
      'room_id': draft.roomId,
      'image_id': draft.workingImageId,
      'mask_ids': draft.masks.map((m) => m.id).toList(),
    });
    return AiGenerationJob.fromJson(result);
  }

  Future<AiGenerationJob> job(String id) async =>
      AiGenerationJob.fromJson(await _json('GET', '/api/jobs/$id'));
  Future<void> cancel(String id) async {
    await _json('POST', '/api/jobs/$id/cancel');
  }

  Future<SavedDesignProject> saveProject(String jobId, String name) async =>
      SavedDesignProject.fromJson(
        await _json('POST', '/api/projects', {'job_id': jobId, 'name': name}),
      );
  Future<List<SavedDesignProject>> projects() async =>
      ((await _json('GET', '/api/projects'))['projects'] as List)
          .map(
            (j) => SavedDesignProject.fromJson(
              Map<String, dynamic>.from(j as Map),
            ),
          )
          .toList();
  void close() => _client.close();
}

Future<RoomImage> _saveReceived(Uint8List bytes, String id) async =>
    RoomImageService.instance.importImage(
      XFile.fromData(bytes, name: '$id.png', path: '$id.png'),
    );
