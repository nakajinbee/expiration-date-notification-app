import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'db.dart';
import 'list.dart';

class CameraPreviewScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraPreviewScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  _CameraPreviewScreenState createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  Map<String, bool> checkedItems = {}; // ここに実装

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('食材を撮影してください'),
        backgroundColor: Color.fromARGB(255, 195, 147, 230), // 濃い紫色に設定
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center, // Center row contents horizontally
        children: <Widget>[
          Spacer(), 
          FloatingActionButton(
            child: Icon(Icons.camera_alt),
            onPressed: () async {
          try {
            await _initializeControllerFuture;

            final path = join(
              (await getTemporaryDirectory()).path,
              '${DateTime.now()}.png',
            );

            final XFile picture = await _controller.takePicture();
            await _controller.pausePreview();
            File imageFile = File(picture.path);
            List<int> imageBytes = await imageFile.readAsBytes();
            String base64Image = base64Encode(imageBytes);

          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Container(
                height: 100,
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(), // 読み込み中のインジケータ
                      Text('読み込み中...'),
                    ],
                  ),
                ),
              );
            },
          );
          fetchData(base64Image).then((jsonString) {
              Navigator.pop(context);
              final List<dynamic> jsonData = json.decode(jsonString);

              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    height: 400, 
                    color: Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text('取得したデータ'),
                          Expanded(
                            child: ListView.builder(
                              itemCount: jsonData.length,
                              itemBuilder: (BuildContext context, int index) {
                                // 各アイテムのデータを取得
                                final item = jsonData[index];
                                item['is_checked'] = true; 
                                return CheckboxListTile(
                                    value: checkedItems[item['id']] ?? true, // チェック状態をcheckedItemsで管理
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        checkedItems[item['id']] = newValue!; // チェック状態が変更されたら、checkedItemsを更新
                                      });
                                    },
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: Text(item['name']),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text('賞味期限: ${item['expiration_date']}'),
                                      Text('保存方法: ${item['storage_method']}'),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Expanded(
                              child: ElevatedButton(
                                child: const Text('撮り直す'),
                                onPressed: () async {
                                  // カメラのプレビューを再開
                                  await _controller.resumePreview();
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple, 
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('登録する'),
                                onPressed: () async {
                                  final dbHelper = DatabaseHelper.instance;
                                  for (var item in jsonData) {
                                  final Map<String, dynamic> itemWithoutIsChecked = Map.from(item)..remove('is_checked');
                                  await dbHelper.insertFoodItem(itemWithoutIsChecked);    
                                }
                                  Navigator.pop(context);
                                  await _controller.resumePreview();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('食材のデータを登録しました。',
                                                style: TextStyle(fontSize: 18), // テキストサイズの調整
                                              ),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                      width: 280.0, // Width of the SnackBar.
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, // Inner padding for SnackBar content.
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                        ],
                      ),
                    ),
                  );
                },
              );
            }).catchError((error) async {
              // エラーハンドリング
              print('Error fetching data: $error');
              final snackBar = SnackBar(
                content: Text('もう一度撮影してください'),
                duration: Duration(seconds: 1),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              await _controller.resumePreview();
            });
          } catch (e) {
            print(e);
          }
        },
      ),
          SizedBox(width: 20), // Provide some horizontal space between the buttons
          FloatingActionButton.extended(
            icon: Icon(Icons.list), // Optional: You can remove the icon if you prefer text only
            label: Text('食材一覧'), // Set text for the button
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FoodItemListScreen()),
              );
            },
          ),
          SizedBox(width: 20), // Provide some horizontal space between the buttons
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('撮影した写真')),
      body: Image.file(File(imagePath)),
    );
  }
}

Future<String> fetchData(String base64Image) async {
  String apiKey = dotenv.env['OPENAI_API_KEY']!;
  String prompt = await rootBundle.loadString('assets/prompt.txt');
  DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyy年M月d日').format(now);
  prompt = prompt + "今日の日付は$formattedDateです";



  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    },
    body: jsonEncode({
      "model": "gpt-4o",
      "messages": [
        {
          "role": "user", 
          "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,${base64Image}"}}
          ]
        }
      ],
      "temperature": 0.7,
    }),
  );
  print(response);

  if (response.statusCode == 200) {
    // サーバーからのレスポンスが成功した場合
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
    print(decodedResponse);
    String jsonString = decodedResponse["choices"][0]["message"]["content"];
    String cleanedJsonString = jsonString.replaceAll(RegExp(r'^\s*```json\s*|\s*```\s*$'), '');
    return cleanedJsonString;
  } else {
    // サーバーからのレスポンスが失敗した場合
    throw Exception('Failed to load data');
  }
}
