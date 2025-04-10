
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../domain/face_scan_repository.dart';

class FaceScanRepositoryImpl implements FaceScanRepository {
  final String backendUrl = "backend_url_host"; 

  @override
  Future<void> sendFaceImage(String lockUuid, String imagePath) async {
    final uri = Uri.parse(backendUrl);

    
    final request = http.MultipartRequest("POST", uri)
      ..fields['lockUuid'] = lockUuid
      ..files.add(await http.MultipartFile.fromPath("faceImage", imagePath));

    final StreamedResponse response = await request.send();

    
    if (response.statusCode != 200) {
      final responseString = await response.stream.bytesToString();
      throw Exception('Failed to send face image. Status: ${response.statusCode}, Body: $responseString');
    }
  }
}
