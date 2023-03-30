import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> processImage(File file) async {
  // Create a multipart request for POST method with a file in the request body
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://20.80.80.198/api/upload'),
  )..files.add(await http.MultipartFile.fromPath(
      'file_uploaded',
      file.path,
    ));

  // Send the request
  http.StreamedResponse response = await request.send();

  // Check if the request was successful
  if (response.statusCode == 200) {
    // Parse the response JSON
    Map<String, dynamic> data =
        jsonDecode(await response.stream.bytesToString());

    // Return the result and error
    return {
      'result': data['result'] ?? '',
      'error': data['error'] ?? '',
    };
  } else {
    // If the request failed, throw an error
    throw Exception('Failed to upload image');
  }
}
