import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> exportDesignImage(Uint8List bytes, String id, Rect origin) async {
  final name = 'sanaa-$id.png';
  final file = XFile.fromData(bytes, mimeType: 'image/png', name: name);
  if (kIsWeb) {
    await file.saveTo(name);
    return true;
  }
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: [name],
        sharePositionOrigin: origin,
      ),
    );
    return result.status == ShareResultStatus.success;
  }
  final location = await getSaveLocation(
    suggestedName: name,
    acceptedTypeGroups: [
      const XTypeGroup(label: 'PNG зураг', extensions: ['png']),
    ],
  );
  if (location == null) return false;
  await file.saveTo(location.path);
  return true;
}
