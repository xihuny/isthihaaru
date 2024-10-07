import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/image_editor_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Image Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImageEditorScreen(imagePath: pickedFile.path),
        ),
      );
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    print(status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Generator'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await _requestPermission(Permission.camera);
                _pickImage(context, ImageSource.camera);
              },
              child: const Text('Capture Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _requestPermission(Permission.storage);
                _pickImage(context, ImageSource.gallery);
              },
              child: const Text('Choose Image'),
            ),
          ],
        ),
      ),
    );
  }
}
