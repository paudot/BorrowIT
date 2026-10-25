import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'photo_helper.dart';
import 'package:image_picker/image_picker.dart';

// Form for returning a borrowed item: a note, then the "after" photo.
// Submitting it saves the photo and sets the request status to Returned.
class ReturnPage extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> request;

  const ReturnPage({super.key, required this.requestId, required this.request});

  @override
  State<ReturnPage> createState() => _ReturnPageState();
}

class _ReturnPageState extends State<ReturnPage> {
  static const Color primaryBlue = Color(0xFF1E40AF);

  TextEditingController noteField = TextEditingController();
  File? afterPhoto;
  bool photoError = false;
  bool loading = false;

  @override
  void dispose() {
    noteField.dispose();
    super.dispose();
  }

    // Take a photo with the camera or choose one from the gallery
  Future<void> attachPhoto(ImageSource source) async {
    ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      File? selectedImage = await pickPhoto(source);
      if (selectedImage != null) {
        setState(() {
          afterPhoto = selectedImage;
          photoError = false;
        });
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not open the camera or gallery.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Save the photo, then mark the request as Returned in Firestore
  Future<void> submitReturn() async {
    // The photo is required
    if (afterPhoto == null) {
      setState(() {
        photoError = true;
      });
      return;
    }

    ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    NavigatorState navigator = Navigator.of(context);

    setState(() {
      loading = true;
    });

    try {
      await savePhoto(afterPhoto!, widget.requestId, 'after');
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
        'status': 'Returned',
        'returnNote': noteField.text.trim(),
        'returnedAt': FieldValue.serverTimestamp(),
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text('Item returned. Thank you!'),
          backgroundColor: Color(0xFF166534),
        ),
      );
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not submit the return. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Return Item',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Which item is being returned
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.request['equipmentName'] ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.request['category'] ?? '',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Note (optional)
            Text(
              'Condition note (optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: noteField,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Example: Returned in good condition.',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),

            // After photo (required)
            Text(
              'After photo (required)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
                        Container(
              width: double.infinity,
              height: 200,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: photoError ? Colors.red : Colors.grey[300]!,
                ),
              ),
              child: afterPhoto == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_camera_outlined,
                              size: 40, color: Colors.grey[400]),
                          SizedBox(height: 8),
                          Text(
                            'No photo yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : Image.file(afterPhoto!, fit: BoxFit.cover),
            ),
            if (photoError)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Please add an after photo.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => attachPhoto(ImageSource.camera),
                    icon: Icon(Icons.photo_camera_outlined),
                    label: Text('Take photo'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => attachPhoto(ImageSource.gallery),
                    icon: Icon(Icons.photo_library_outlined),
                    label: Text('Gallery'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : submitReturn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('Submit return'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}