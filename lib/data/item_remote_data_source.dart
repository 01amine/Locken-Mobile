import 'dart:convert';
import 'package:http/http.dart' as http;
import 'item_model.dart';

class ItemRemoteDataSource {
  final http.Client client;

  ItemRemoteDataSource({required this.client});

  Future<ItemModel> getItemById(String itemId) async {
    final url =
        Uri.parse('https://43c4-41-111-161-92.ngrok-free.app/items/$itemId');
    final response = await client.get(url);

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return ItemModel.fromJson(jsonBody);
    } else {
      throw Exception('Failed to load item');
    }
  }
}
