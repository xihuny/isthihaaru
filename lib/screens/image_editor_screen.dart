import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../widgets/editable_text.dart';

class ImageEditorScreen extends StatefulWidget {
  final String imagePath;

  const ImageEditorScreen({super.key, required this.imagePath});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  List<CustomEditableText> texts = [];
  int? activeTextIndex;
  ScreenshotController screenshotController = ScreenshotController();

  void _addText() {
    _showEditDialog(null);
  }

  Future<void> _saveImage() async {
    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }

      final Uint8List? imageBytes = await screenshotController.capture();
      if (imageBytes != null) {
        // Get the public Pictures directory
        Directory? directory = await getExternalStorageDirectory();
        String newPath = "";
        List<String> paths = directory!.path.split("/");
        for (int x = 1; x < paths.length; x++) {
          String folder = paths[x];
          if (folder != "Android") {
            newPath += "/$folder";
          } else {
            break;
          }
        }
        newPath = "$newPath/Pictures";
        directory = Directory(newPath);

        // Create the directory if it doesn't exist
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        // Generate a unique file name
        final String fileName =
            'edited_image_${DateTime.now().millisecondsSinceEpoch}.png';
        final String filePath = '${directory.path}/$fileName';

        // Save the image
        final File file = File(filePath);
        await file.writeAsBytes(imageBytes);

        // Notify the media store about the new file
        await _scanFile(filePath);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image saved to gallery')),
        );
      } else {
        throw Exception('Failed to capture image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image: ${e.toString()}')),
      );
    }
  }

  Future<void> _scanFile(String path) async {
    try {
      await const MethodChannel('com.devoup.isthihaaru/media_scanner')
          .invokeMethod('scanFile', {'path': path});
    } on PlatformException catch (e) {
      print("Failed to scan file: ${e.message}");
    }
  }

  void _showEditDialog(int? index) {
    final textController =
        TextEditingController(text: index != null ? texts[index].text : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            const Text('Edit Text', style: TextStyle(fontFamily: 'MVAWaheed')),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(fontFamily: 'MVAWaheed'),
          decoration: const InputDecoration(hintText: 'Enter text'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final newText = textController.text.trim();
              if (newText.isNotEmpty) {
                setState(() {
                  if (index == null) {
                    // Adding new text
                    texts.add(CustomEditableText(
                      text: newText,
                      position: const Offset(100, 100),
                      color: Colors.white,
                      fontSize: 20,
                      rotation: 0,
                    ));
                    activeTextIndex = texts.length - 1;
                  } else {
                    // Updating existing text
                    texts[index].text = newText;
                  }
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(fontFamily: 'MVAWaheed')),
          ),
        ],
      ),
    );
  }

  void _toggleActiveText(int index) {
    setState(() {
      activeTextIndex = (activeTextIndex == index) ? null : index;
    });
  }

  void _handleTextTap(int index) {
    _showEditDialog(index);
  }

  void _deleteSelectedText() {
    if (activeTextIndex != null) {
      setState(() {
        texts.removeAt(activeTextIndex!);
        activeTextIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Edit Image'),
        actions: [
          if (activeTextIndex != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedText,
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveImage,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          setState(() {
            activeTextIndex = null;
          });
        },
        child: Screenshot(
          controller: screenshotController,
          child: Stack(
            children: [
              Image.file(File(widget.imagePath)),
              ...texts.asMap().entries.map((entry) {
                final index = entry.key;
                final text = entry.value;
                return EditableTextWidget(
                  key: ValueKey(text),
                  text: text,
                  isActive: index == activeTextIndex,
                  onTap: () => _handleTextTap(index),
                  onUpdate: (updatedText) {
                    setState(() {
                      texts[index] = updatedText;
                      activeTextIndex = index;
                    });
                  },
                );
              }),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addText,
        child: const Icon(Icons.add),
      ),
    );
  }
}
