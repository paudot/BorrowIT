import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

// The photos are saved on the phone itself (local storage), not in the database.
// Each file is named after its request: <requestId>_before.jpg or <requestId>_after.jpg

// Photos live in the app documents folder named requestId_before.jpg or requestId_after.jpg
// Gets the file where a photo is (or will be) saved
Future<File> photoFile(String requestId, String type) async {
  Directory folder = await getApplicationDocumentsDirectory();
  return File('${folder.path}/${requestId}_$type.jpg');
}

// Opens the camera or the gallery. Returns null if the user cancels.
Future<File?> pickPhoto(ImageSource source) async {
  XFile? selectedImage = await ImagePicker().pickImage(source: source);
  if (selectedImage == null) {
    return null;
  }
  return File(selectedImage.path);
}

// Copies the picked photo into local storage
Future<void> savePhoto(File photo, String requestId, String type) async {
  File target = await photoFile(requestId, type);
  await photo.copy(target.path);
  // Clear the old cached picture so the new photo shows
  await FileImage(target).evict();
}

// Deletes both photos of a request (used when the request is cancelled)
Future<void> deletePhotos(String requestId) async {
  for (String type in ['before', 'after']) {
    File file = await photoFile(requestId, type);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

// Shows a photo in a bigger view
void showPhoto(BuildContext context, File photo) {
  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      child: InteractiveViewer(child: Image.file(photo)),
    ),
  );
}

// Shows the saved photo of a request (before or after).
class PhotoBox extends StatefulWidget {
  final String requestId;
  final String type; // 'before' or 'after'

    const PhotoBox({
    super.key,
    required this.requestId,
    required this.type,
  });

  @override
  State<PhotoBox> createState() => _PhotoBoxState();
}

class _PhotoBoxState extends State<PhotoBox> {
  File? photo;

  @override
  void initState() {
    super.initState();
    loadPhoto();
  }

  // Looks for the saved photo on the phone
  Future<void> loadPhoto() async {
    File file = await photoFile(widget.requestId, widget.type);
    if (await file.exists() && mounted) {
      setState(() {
        photo = file;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String label = widget.type == 'before' ? 'Before' : 'After';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label photo',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 6),
        GestureDetector(
          onTap: photo == null ? null : () => showPhoto(context, photo!),
          child: Container(
            width: double.infinity,
            height: 100,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: photo == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera_outlined,
                            color: Colors.grey[400]),
                        SizedBox(height: 4),
                        Text(
                          'No photo yet',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : Image.file(photo!, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }
}