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
  EditableTextWidget? activeTextWidget;
  ScreenshotController screenshotController = ScreenshotController();
  bool _isSaving = false;

  void _addText() {
    _showEditDialog(null);
  }

  Future<void> _saveImage() async {
    try {
      // Deselect all texts before saving
      setState(() {
        activeTextWidget = null;
      });

      // Wait for the next frame to ensure the UI has updated
      await Future.delayed(Duration.zero);

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
          const SnackBar(
            content: Text(
              'ފޮޓޯ ގެލެރީއަށް ރައްކާކުރެވިއްޖެ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),
        );
      } else {
        throw Exception('ފޮޓޯ ނެގުމުގައި މައްސަލަ ޖެހިއްޖެ');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ފޮޓޯ ރައްކާކުރުމުގައި މައްސަލަ ޖެހިއްޖެ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
        ),
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
                    style: const TextStyle(fontSize: 20),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
                            hasShadow:
                                false, // Explicitly set to false for new text
                          ));
                          activeTextWidget = EditableTextWidget(
                            text: texts.last,
                            onSelect: _selectText,
                            onEdit: () => _showEditDialog(texts.length - 1),
                            onUpdate: (updatedText) {
                              setState(() {
                                int index = texts.indexOf(updatedText);
                                if (index != -1) {
                                  texts[index] = updatedText;
                                }
                              });
                            },
                            isActive: true,
                          );
                        } else {
                          // Updating existing text
                          texts[index].text = newText;
                        }
                      });
                    }
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue.withAlpha(30),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    elevation: 0, // No elevation
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'ރަނގަޅު',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.blue,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withAlpha(30),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'ކެންސަލް',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 202, 50, 39),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _selectText(EditableTextWidget selectedWidget) {
    setState(() {
      if (activeTextWidget != selectedWidget) {
        activeTextWidget = selectedWidget;
      } else if (activeTextWidget == selectedWidget) {
        // If tapping the already active text, open edit dialog
        _showEditDialog(texts.indexOf(selectedWidget.text));
      }
    });
  }

  void _deleteSelectedText() {
    debugPrint('delete');
    if (activeTextWidget != null) {
      setState(() {
        int index = texts.indexOf(activeTextWidget!.text);
        if (index != -1) {
          texts.removeAt(index);
          activeTextWidget = null;
        }
      });
    }
  }

  void _changeTextColor() {
    if (activeTextWidget != null) {
      _showColorPickerDialog(texts.indexOf(activeTextWidget!.text));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ފުރަތަމަ ލިޔުމެއް ސެލެކްޓް ކުރޭ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
        ),
      );
    }
  }

  void _changeTextFont() {
    if (activeTextWidget != null) {
      _showFontSelectionDialog(texts.indexOf(activeTextWidget!.text));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ފުރަތަމަ ލިޔުމެއް ސެލެކްޓް ކުރޭ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
        ),
      );
    }
  }

  void _showColorPickerDialog(int index) {
    Color currentColor = texts[index].color;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'ކުލައެއް ސެލެކްޓް ކޮށްލާ',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
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
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.all(Colors.blue.withAlpha(25)),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text('ކުލަ ބަދަލުކޮށްލާ',
                      style: TextStyle(fontSize: 20, color: Colors.blue)),
                ),
              ),
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
          title: const Text(
            'ފޮންޓް ސެލެކްޓް ކޮށްލާ',
            style: const TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFontListTile(index, 'MVAWaheed', 'އެމްވީ އޭ ވަހީދު'),
                _cutomDivider(),
                _buildFontListTile(index, 'aammufkF', 'އާއްމު އެފް ކޭ'),
                _cutomDivider(),
                _buildFontListTile(index, 'AKRasmee', 'އޭކޭ ރަސްމީ'),
                _cutomDivider(),
                _buildFontListTile(index, 'FarumaV2', 'ފަރުމާ'),
                _cutomDivider(),
                _buildFontListTile(
                    index, 'MageyHuseynu-Regular', 'މަސްބުން ހުސޭނު'),
                _cutomDivider(),
                _buildFontListTile(index, 'MVBodu', 'އެމްވީ ބޮޑު'),
                _cutomDivider(),
                _buildFontListTile(index, 'MvGaaLhohi', 'އެމްވީ ގާޅޮހި'),
                _cutomDivider(),
                _buildFontListTile(
                    index, 'MvIzyanboduakuru', 'އެމްވީ އިޒްޔަން ބޮޑުއަކުރު'),
                _cutomDivider(),
                _buildFontListTile(
                    index, 'MvIzyanSuruhee', 'އެމްވީ އިޒްޔަން ސުރުޚީ'),
                _cutomDivider(),
                _buildFontListTile(index, 'Mvsuruhee', 'އެމްވީ ސުރުޚީ'),
                _cutomDivider(),
                _buildFontListTile(
                    index, 'MvThakurufaanu', 'އެމްވީ ތަކުރުފާނު'),
                _cutomDivider(),
                _buildFontListTile(
                    index, 'Mvizyanboduakuru3D-Bold', 'އެމްވީ އިޒްޔަން ތްރީޑީ'),
                _cutomDivider(),
                _buildFontListTile(index, 'Mvlhohibold', 'އެމްވީ ޅޮހި ބޯލްޑް'),
                _cutomDivider(),
                _buildFontListTile(
                    index, 'mvtypewritersb_v1', 'އެމްވީ ޓައިޕްރައިޓަރ'),
                _cutomDivider(),
                _buildFontListTile(
                    index, 'Randhoo_reg_hinted', 'ރަންދޫ ރެގިއުލާ ހިންޓެޑް'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _cutomDivider() {
    return Divider(
      height: 0.5,
      color: Colors.black.withAlpha(15),
    );
  }

  Widget _buildFontListTile(int index, String fontFamily, String fontName) {
    return ListTile(
      title: Text(
        fontName,
        style: TextStyle(fontFamily: fontFamily, fontSize: 25),
      ),
      onTap: () {
        setState(() {
          texts[index].fontFamily = fontFamily;
        });
        Navigator.of(context).pop();
      },
    );
  }

  void _toggleTextShadow() {
    if (activeTextWidget != null) {
      setState(() {
        int index = texts.indexOf(activeTextWidget!.text);
        if (index != -1) {
          texts[index].hasShadow = !texts[index].hasShadow;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ފުރަތަމަ ލިޔުމެއް ސެލެކްޓް ކުރޭ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('ފޮޓޯ އެޑިޓް ކުރުން',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (activeTextWidget != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white),
                  onPressed: _deleteSelectedText,
                ),
              ),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            // Deselect when tapping outside any text
            setState(() {
              activeTextWidget = null;
            });
          },
          child: Screenshot(
            controller: screenshotController,
            child: Stack(
              children: [
                Image.file(File(widget.imagePath)),
                ...texts.map((text) {
                  return EditableTextWidget(
                    key: ValueKey(text),
                    text: text,
                    isActive: activeTextWidget?.text == text,
                    onSelect: _selectText,
                    onEdit: () => _showEditDialog(texts.indexOf(text)),
                    onUpdate: (updatedText) {
                      setState(() {
                        int index = texts.indexOf(text);
                        if (index != -1) {
                          texts[index] = updatedText;
                        }
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCircleButton(
                    icon: Icons.text_fields,
                    label: 'ލިޔުން',
                    onPressed: _addText,
                    heroTag: 'add_text',
                  ),
                  const SizedBox(width: 16),
                  _buildCircleButton(
                    icon: Icons.font_download,
                    label: 'ފޮންޓް',
                    onPressed: _changeTextFont,
                    heroTag: 'change_font',
                  ),
                  const SizedBox(width: 16),
                  _buildCircleButton(
                    icon: Icons.color_lens,
                    label: 'ކުލަ',
                    onPressed: _changeTextColor,
                    heroTag: 'change_color',
                  ),
                  const SizedBox(width: 16),
                  _buildCircleButton(
                    icon: activeTextWidget != null &&
                            texts[texts.indexOf(activeTextWidget!.text)]
                                .hasShadow
                        ? Icons.visibility
                        : Icons.visibility_off,
                    label: 'ހިޔަނި',
                    onPressed: _toggleTextShadow,
                    heroTag: 'toggle_shadow',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSaveButton(),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required String heroTag,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: heroTag,
          backgroundColor: Colors.blue,
          onPressed: onPressed,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Container(
          width: 200,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 44, 142, 45),
                Color.fromARGB(255, 86, 185, 91)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: ElevatedButton(
            onPressed: () async {
              setState(() => _isSaving = true);
              await _saveImage();
              setState(() => _isSaving = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.save_alt, color: Colors.white),
                      SizedBox(width: 8),
                      Padding(
                        padding: EdgeInsets.only(top: 7, right: 5),
                        child: Text(
                          'ފޮޓޯ ސޭވް ކޮށްލާ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
