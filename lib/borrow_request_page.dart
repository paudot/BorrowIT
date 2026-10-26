import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'helpers.dart';
import 'photo_helper.dart';

class BorrowRequestPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final String? requestId;              // only set when editing a request
  final Map<String, dynamic>? existing; // the old request data

    const BorrowRequestPage({
    super.key,
    required this.item,
    this.requestId,
    this.existing,
  });

  @override
  State<BorrowRequestPage> createState() => _BorrowRequestPageState();
}

class _BorrowRequestPageState extends State<BorrowRequestPage> {
  final formKey = GlobalKey<FormState>();
  TextEditingController dateNeededField = TextEditingController();
  TextEditingController returnDateField = TextEditingController();
  TextEditingController purposeField = TextEditingController();

  DateTime? dateNeeded;
  DateTime? returnDate;
  bool isLoading = false;

  File? beforePhoto;          // the "before" photo of the item
  bool photoChanged = false;  // true when the student picked a new photo
  bool photoMissing = false;  // true when the student forgot the photo

  static const Color primaryBlue = Color(0xFF1E40AF);

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      dateNeeded = (widget.existing!['dateNeeded'] as Timestamp).toDate();
      returnDate = (widget.existing!['returnDate'] as Timestamp).toDate();
      dateNeededField.text = formatDate(dateNeeded!);
      returnDateField.text = formatDate(returnDate!);
      purposeField.text = widget.existing!['purpose'] ?? '';

      // Load the saved "before" photo of this request
      photoFile(widget.requestId!, 'before').then((file) {
        if (file.existsSync() && mounted) {
          setState(() {
            beforePhoto = file;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    dateNeededField.dispose();
    returnDateField.dispose();
    purposeField.dispose();
    super.dispose();
  }
  // Return date cannot be before the date needed, so it is cleared if needed
  // Pick the date needed
  Future<void> pickDateNeeded() async {
    DateTime today = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (dateNeeded != null && dateNeeded!.isAfter(today))
          ? dateNeeded!
          : today,
      firstDate: today,
      lastDate: today.add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        dateNeeded = picked;
        dateNeededField.text = formatDate(picked);

        // Clear the return date if it is now earlier than the date needed
        if (returnDate != null && returnDate!.isBefore(picked)) {
          returnDate = null;
          returnDateField.clear();
        }
      });
    }
  }

  // Pick the return date (cannot be before the date needed)
  Future<void> pickReturnDate() async {
    if (dateNeeded == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please choose the date needed first.')),
      );
      return;
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: returnDate ?? dateNeeded!,
      firstDate: dateNeeded!,
      lastDate: dateNeeded!.add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        returnDate = picked;
        returnDateField.text = formatDate(picked);
      });
    }
  }
  // setState is what shows the picked photo. Without it the photo box stays empty
  // Take a photo with the camera or choose one from the gallery
  Future<void> attachPhoto(ImageSource source) async {
    ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
            File? selectedImage = await pickPhoto(source);
      if (selectedImage != null) {
        setState(() {
          beforePhoto = selectedImage;
          photoChanged = true;
          photoMissing = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Photo attached.'),
            backgroundColor: Color(0xFF166534),
          ),
        );
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

  // New request: photo is saved on the phone first using the request id, then the
  // request goes to Firestore with status Pending. Edit only updates dates and purpose
  // Save the request in Firestore (new request or edited request)
  Future<void> submitRequest() async {
    bool formOk = formKey.currentState!.validate();

    // A new request needs a "before" photo of the item
    bool photoOk = widget.requestId != null || beforePhoto != null;
    setState(() {
      photoMissing = !photoOk;
    });
    if (!formOk || !photoOk) {
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    NavigatorState navigator = Navigator.of(context);

    setState(() {
      isLoading = true;
    });

    try {
      if (widget.requestId == null) {
        // New request: get the id first so the photo can be named after it
        DocumentReference newRequest =
            FirebaseFirestore.instance.collection('requests').doc();

        // The photo is saved on the phone, not in Firestore
        await savePhoto(beforePhoto!, newRequest.id, 'before');

        await newRequest.set({
          'userId': user.uid,
          'equipmentId': widget.item['id'],
          'equipmentName': widget.item['title'],
          'category': widget.item['category'],
          'imagePath': widget.item['imagePath'] ?? '',
          'dateNeeded': Timestamp.fromDate(dateNeeded!),
          'returnDate': Timestamp.fromDate(returnDate!),
          'purpose': purposeField.text.trim(),
          // Every new request starts as Pending. The reminderId is used for notifications
          'status': 'Pending',
          'reminderId': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Go back to the equipment list and show a message
        navigator.pop();
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Request submitted for ${widget.item['title']}.'),
            backgroundColor: Color(0xFF166534),
          ),
        );
      } else {
        // Editing a pending request
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.requestId)
            .update({
          'dateNeeded': Timestamp.fromDate(dateNeeded!),
          'returnDate': Timestamp.fromDate(returnDate!),
          'purpose': purposeField.text.trim(),
        });

        // Save the new photo only if the student picked another one
        if (photoChanged && beforePhoto != null) {
          await savePhoto(beforePhoto!, widget.requestId!, 'before');
        }

        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Request updated.'),
            backgroundColor: Color(0xFF166534),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not save the request. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  InputDecoration fieldStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> item = widget.item;
    TextStyle labelStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.requestId == null ? 'Borrow Request' : 'Edit Request',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected equipment summary
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: EquipmentImage(
                        key: ValueKey(item['imagePath'] ?? ''),
                        imagePath: item['imagePath'] ?? '',
                        category: item['category'] ?? '',
                        iconSize: 30,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] ?? '',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            item['category'] ?? '',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Date needed
              Text('Date needed', style: labelStyle),
              SizedBox(height: 8),
              TextFormField(
                controller: dateNeededField,
                readOnly: true,
                onTap: pickDateNeeded,
                decoration:
                    fieldStyle('Choose a date', Icons.calendar_today_outlined),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please choose the date needed'
                    : null,
              ),
              SizedBox(height: 16),

              // Return date
              Text('Return date', style: labelStyle),
              SizedBox(height: 8),
              TextFormField(
                controller: returnDateField,
                readOnly: true,
                onTap: pickReturnDate,
                decoration:
                    fieldStyle('Choose a date', Icons.event_available_outlined),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please choose the return date'
                    : null,
              ),
              SizedBox(height: 16),

              // Purpose
              Text('Purpose', style: labelStyle),
              SizedBox(height: 8),
              TextFormField(
                controller: purposeField,
                maxLines: 3,
                decoration: fieldStyle(
                    'Example: Capstone presentation in Room 305',
                    Icons.edit_note_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the purpose';
                  }
                  if (value.trim().length < 5) {
                    return 'Please describe the purpose a bit more';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Before photo (condition of the item before borrowing)
              Text('Photo of the item (before borrowing)', style: labelStyle),
              SizedBox(height: 4),
              Text(
                'This records any damage the item already has.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 170,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: photoMissing ? Colors.red : Colors.grey[300]!,
                  ),
                ),
                child: beforePhoto == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera_outlined,
                                size: 40, color: Colors.grey[400]),
                            SizedBox(height: 6),
                            Text(
                              'No photo yet',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : Image.file(beforePhoto!, fit: BoxFit.cover),
              ),
              if (photoMissing)
                Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Please attach a photo of the item',
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
              SizedBox(height: 28),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isLoading ? null : submitRequest,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.requestId == null
                              ? 'Submit request'
                              : 'Save changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}