import 'package:flutter/material.dart';

// Turns a date into text like "Oct 22, 2026"
String formatDate(DateTime date) {
  List<String> months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
// Icon used when an equipment has no image
IconData iconForCategory(String category) {
  if (category == 'Computers') return Icons.laptop;
  if (category == 'Presentation') return Icons.videocam_outlined;
  if (category == 'Media') return Icons.camera_alt_outlined;
  if (category == 'Cables') return Icons.cable_outlined;
  if (category == 'Audio') return Icons.mic_none_outlined;
  return Icons.devices_other;
}
// Status chip colors
Color statusBackground(String status) {
  if (status == 'Pending') return Color(0xFFFEF3C7);
  if (status == 'Approved') return Color(0xFFDBEAFE);
  if (status == 'Borrowed') return Color(0xFFEDE9FE);
  if (status == 'Returned') return Color(0xFFDCFCE7);
  return Color(0xFFFEE2E2); // Rejected
}
Color statusTextColor(String status) {
  if (status == 'Pending') return Color(0xFF92400E);
  if (status == 'Approved') return Color(0xFF1E40AF);
  if (status == 'Borrowed') return Color(0xFF5B21B6);
  if (status == 'Returned') return Color(0xFF166534);
  return Color(0xFF991B1B); // Rejected
}
// Shows the equipment image from the app's assets folder.
// If there is no image, it shows an icon instead.
class EquipmentImage extends StatelessWidget {
  final String imagePath;
  final String category;
  final double iconSize;

    const EquipmentImage({
    super.key,
    required this.imagePath,
    required this.category,
    this.iconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconBox = Center(
      child: Icon(
        iconForCategory(category),
        size: iconSize,
        color: Color(0xFF1E40AF),
      ),
    );

    if (imagePath.isEmpty) {
      return iconBox;
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => iconBox,
    );
  }
}