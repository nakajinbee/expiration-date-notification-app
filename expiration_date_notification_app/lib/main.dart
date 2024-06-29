import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("アプリ起動");
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  await dotenv.load(fileName: ".env");
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  MyApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraPreviewScreen(camera: camera),
    );
  }
}