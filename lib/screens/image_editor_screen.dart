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
    Color currentColor = index != null ? texts[index].color : Colors.white;
    bool showColorPicker = false;
    String currentFont = index != null ? texts[index].fontFamily : 'MVAWaheed';

    void _showFontSelectionDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title:
                Text('ފޮންޓް ހޮވާ', style: TextStyle(fontFamily: 'MVAWaheed')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('MVAWaheed',
                      style: TextStyle(fontFamily: 'MVAWaheed')),
                  onTap: () {
                    Navigator.of(context).pop('MVAWaheed');
                  },
                ),
                ListTile(
                  title: Text('Arial', style: TextStyle(fontFamily: 'Arial')),
                  onTap: () {
                    Navigator.of(context).pop('Arial');
                  },
                ),
                // Add more font options here
              ],
            ),
          );
        },
      ).then((selectedFont) {
        if (selectedFont != null) {
          setState(() {
            currentFont = selectedFont;
          });
        }
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!showColorPicker) ...[
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        child: TextField(
                          controller: textController,
                          autofocus: true,
                          style: const TextStyle(
                              fontFamily: 'MVAWaheed', fontSize: 20),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showColorPicker = true;
                              });
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: currentColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.font_download),
                            onPressed: _showFontSelectionDialog,
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text('ކުލަ ހޮވާ',
                          style:
                              TextStyle(fontFamily: 'MVAWaheed', fontSize: 18)),
                      const SizedBox(height: 20),
                      ColorPicker(
                        pickerColor: currentColor,
                        onColorChanged: (color) {
                          setState(() {
                            currentColor = color;
                          });
                        },
                        enableAlpha: true,
                        displayThumbColor: true,
                        paletteType: PaletteType.hsvWithHue,
                        pickerAreaHeightPercent: 0.8,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!showColorPicker)
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              final newText = textController.text.trim();
                              if (newText.isNotEmpty) {
                                this.setState(() {
                                  if (index == null) {
                                    // Adding new text
                                    texts.add(CustomEditableText(
                                      text: newText,
                                      position: const Offset(100, 100),
                                      color: currentColor,
                                      fontSize: 30,
                                      rotation: 0,
                                    ));
                                    activeTextIndex = texts.length - 1;
                                  } else {
                                    // Updating existing text
                                    texts[index].text = newText;
                                    texts[index].color = currentColor;
                                  }
                                });
                              }
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Color(
                                  0xFF90A4AE), // Soft blue-grey, slightly darker
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('ރަނގަޅު',
                                style: TextStyle(fontFamily: 'MVAWaheed')),
                          ),
                        ),
                      SizedBox(height: 4), // Add some space between buttons
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            if (showColorPicker) {
                              setState(() {
                                showColorPicker = false;
                              });
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Color(0xFFB0BEC5), // Soft blue-grey
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            showColorPicker ? 'ނިންމާ' : 'ކެންސަލް',
                            style: TextStyle(fontFamily: 'MVAWaheed'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _addText,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
