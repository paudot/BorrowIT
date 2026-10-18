import 'package:borrow_it/profile_page.dart';
import 'package:flutter/material.dart';
import 'equipment_details_page.dart'; // Import the details page

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({Key? key}) : super(key: key);

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  int _selectedCategoryIndex = 0;
  int _selectedBottomNavIndex = 0;
  String _searchQuery = '';

  final List<String> categories = [
    'All',
    'Computers',
    'Presentation',
    'Media',
    'Cables',
    'Audio',
  ];

  // Dummy equipment data using built-in Flutter Icons
  final List<Map<String, dynamic>> equipmentList = [
    {
      'title': 'Laptop',
      'category': 'Computers',
      'icon': Icons.laptop,
      'available': 3,
      'total': 5,
      'isAvailable': true,
      'description': 'Laptop for coursework, presentations and programming. Charger and carrying case are included with every loan.',
      'includes': 'Charger, case',
      'pickup': 'CICT Equipment room',
    },
    {
      'title': 'Projector',
      'category': 'Presentation',
      'icon': Icons.videocam_outlined,
      'available': 2,
      'total': 4,
      'isAvailable': true,
      'description': 'High-definition portable projector suitable for classroom presentations and group projects.',
      'includes': 'Power cable, HDMI cable',
      'pickup': 'Media center',
    },
    {
      'title': 'Camera',
      'category': 'Media',
      'icon': Icons.camera_alt_outlined,
      'available': 0,
      'total': 2,
      'isAvailable': false,
      'description': 'Digital mirrorless camera for photography projects, media production, and campus events.',
      'includes': 'Lens, strap, battery',
      'pickup': 'AV department',
    },
    {
      'title': 'HDMI cable',
      'category': 'Cables',
      'icon': Icons.cable_outlined,
      'available': 8,
      'total': 10,
      'isAvailable': true,
      'description': 'Standard 2-meter high-speed HDMI cable for connecting laptops to displays and projectors.',
      'includes': 'Cable tie',
      'pickup': 'Equipment room',
    },
    {
      'title': 'Extension cord',
      'category': 'Cables',
      'icon': Icons.power_outlined,
      'available': 2,
      'total': 5,
      'isAvailable': true,
      'description': 'Heavy-duty 5-meter multi-outlet extension cord for workshops and group study areas.',
      'includes': 'None',
      'pickup': 'Main desk',
    },
    {
      'title': 'Microphone',
      'category': 'Audio',
      'icon': Icons.mic_none_outlined,
      'available': 1,
      'total': 3,
      'isAvailable': true,
      'description': 'USB condenser microphone for audio recording, presentations, and podcasting.',
      'includes': 'Stand, USB cable',
      'pickup': 'Media center',
    },
  ];

  static const Color primaryBlue = Color(0xFF1E40AF);

  @override
  Widget build(BuildContext context) {
    // Filter by category and search query
    final selectedCategoryName = categories[_selectedCategoryIndex];
    
    final filteredEquipment = equipmentList.where((item) {
      final matchesCategory = selectedCategoryName == 'All' ||
          item['category'] == selectedCategoryName;
      final matchesSearch =
          item['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header & Search Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Profile Avatar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Good day, Juan',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Equipment',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      // Profile Circle
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: primaryBlue,
                        child: const Text(
                          'JD',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search laptop, projector, cable...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: primaryBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category Filter Pills
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(categories[index]),
                      selected: isSelected,
                      selectedColor: primaryBlue,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? primaryBlue : Colors.grey[300]!,
                        ),
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Equipment Grid View
            Expanded(
              child: filteredEquipment.isEmpty
                  ? Center(
                      child: Text(
                        'No equipment found.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: filteredEquipment.length,
                      itemBuilder: (context, index) {
                        final item = filteredEquipment[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EquipmentDetailsPage(item: item),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon Display Box
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      item['icon'] as IconData,
                                      size: 48,
                                      color: primaryBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Title
                                Text(
                                  item['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Category
                                Text(
                                  item['category'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Availability Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item['isAvailable']
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item['isAvailable']
                                        ? '${item['available']} available'
                                        : 'Unavailable',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: item['isAvailable']
                                          ? const Color(0xFF166534)
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomNavIndex,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) {
          if(index == 3){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>ProfilePage()));
          }
          setState(() {
            _selectedBottomNavIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Equipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
            
          ),
        ],
      ),
    );
  }
}