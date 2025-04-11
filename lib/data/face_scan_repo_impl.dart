import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../domain/face_scan_repository.dart';

class FaceScanRepositoryImpl implements FaceScanRepository {
  final String backendUrl =
      "https://43c4-41-111-161-92.ngrok-free.app/recognize-face/1";

  @override
  Future<void> sendFaceImage(String lockUuid, String imagePath) async {
    final uri = Uri.parse(backendUrl);

    final request = http.MultipartRequest("POST", uri)
      ..fields['lock_id'] = lockUuid
      ..files.add(await http.MultipartFile.fromPath("file", imagePath));

    final StreamedResponse response = await request.send();

    if (response.statusCode != 200) {
      final responseString = await response.stream.bytesToString();
      throw Exception(
          'Failed to send face image. Status: ${response.statusCode}, Body: $responseString');
    }
  }
}
