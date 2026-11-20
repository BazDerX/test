import 'room_image_service.dart';

/// Future ARCore/ARKit adapters can implement reconstruction independently of
/// camera capture. Capturing a photograph does not produce a 3D room scan.
abstract interface class RoomScanningService {
  bool get supportsReconstruction;
  Future<void> reconstruct(RoomImage image);
}

class UnavailableRoomScanningService implements RoomScanningService {
  const UnavailableRoomScanningService();
  @override
  bool get supportsReconstruction => false;
  @override
  Future<void> reconstruct(RoomImage image) async {
    throw UnsupportedError('3D өрөөний скан хараахан холбогдоогүй байна.');
  }
}
