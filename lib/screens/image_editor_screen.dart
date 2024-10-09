import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../widgets/editable_text.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: TextField(
                    controller: textController,
                    autofocus: true,
                    style:
                        const TextStyle(fontFamily: 'MVAWaheed', fontSize: 20),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
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
                        fontSize: 30,
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
              child: const Text('ރަނގަޅު',
                  style: TextStyle(fontFamily: 'MVAWaheed')),
            ),
          ],
        );
      },
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

  void _changeTextColor() {
    if (activeTextIndex != null) {
      _showColorPickerDialog(activeTextIndex!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a text first')),
      );
    }
  }

  void _changeTextFont() {
    if (activeTextIndex != null) {
      _showFontSelectionDialog(activeTextIndex!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a text first')),
      );
    }
  }

  void _showColorPickerDialog(int index) {
    Color currentColor = texts[index].color;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ކުލަ ހޮވާ',
              style: TextStyle(fontFamily: 'MVAWaheed')),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (color) {
                setState(() {
                  texts[index].color = color;
                });
              },
              enableAlpha: true,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ނިންމާ',
                  style: TextStyle(fontFamily: 'MVAWaheed')),
            ),
          ],
        );
      },
    );
  }

  void _showFontSelectionDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ފޮންޓް ހޮވާ',
              style: TextStyle(fontFamily: 'MVAWaheed')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('MVAWaheed',
                    style: TextStyle(fontFamily: 'MVAWaheed')),
                onTap: () {
                  setState(() {
                    texts[index].fontFamily = 'MVAWaheed';
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title:
                    const Text('Arial', style: TextStyle(fontFamily: 'Arial')),
                onTap: () {
                  setState(() {
                    texts[index].fontFamily = 'Arial';
                  });
                  Navigator.of(context).pop();
                },
              ),
              // Add more font options here
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Edit Image', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(
            color: Colors.white), // This changes the back button color to white
        actions: [
          if (activeTextIndex != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteSelectedText,
            ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
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
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCircleButton(
              icon: Icons.color_lens,
              label: 'ކުލަ',
              onPressed: _changeTextColor,
            ),
            const SizedBox(width: 16),
            _buildCircleButton(
              icon: Icons.font_download,
              label: 'ފޮންޓް',
              onPressed: _changeTextFont,
            ),
            const SizedBox(width: 16),
            _buildCircleButton(
              icon: Icons.add,
              label: 'ލިޔުން',
              onPressed: _addText,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: onPressed,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'MVAWaheed',
            fontSize: 20,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}
