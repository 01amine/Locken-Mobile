import 'face_scan_repository.dart';

class FaceScanUseCase {
  final FaceScanRepository repository;

  FaceScanUseCase({required this.repository});

  Future<void> scanAndSendFace(String lockUuid, String imagePath) async {
    // You can add face detection logic here if needed.
    // For now, we directly send the image to the backend.
    return repository.sendFaceImage(lockUuid, imagePath);
  }
}
