abstract class FaceScanRepository {
  /// Sends the face image to the backend with the provided lock UUID.
  Future<void> sendFaceImage(String lockUuid, String imagePath);
}
