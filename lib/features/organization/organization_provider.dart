import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

final organizationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await ApiClient.get('/organizations/read.php');
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['records'] as List<dynamic>;
  } else if (response.statusCode == 404) {
    return [];
  } else {
    throw Exception('Failed to load organizations');
  }
});
