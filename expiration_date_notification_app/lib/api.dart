import 'dart:io';
import 'package:http/http.dart' as http;

Future uploadImage(File image) async {
  var request = http.MultipartRequest('POST', Uri.parse('Your API URL'));
  request.files.add(await http.MultipartFile.fromPath('image', image.path));
  var response = await request.send();
  if (response.statusCode == 200) {
    print('Image uploaded!');
  } else {
    print('Image upload failed.');
  }
}