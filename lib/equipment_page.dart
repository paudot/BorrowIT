import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';
import 'equipment_details_page.dart';
import 'requests_page.dart';
import 'helpers.dart';
import 'dart:async';
import 'notification_service.dart';

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({super.key});

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  int selectedCategoryIndex = 0;
  String searchQuery = '';
  String userName = '';
  StreamSubscription? requestsListener;
  Map<String, String> lastStatus = {};
  bool firstLoad = true;

  final List<String> categories = [
    'All',
    'Computers',
    'Presentation',
    'Media',
    'Cables',
    'Audio',
  ];

  static const Color primaryBlue = Color(0xFF1E40AF);

  @override
  void initState() {
    super.initState();
    loadUserName();
    listenToRequests();
  }

  // Get the student's name from the users collection
  Future<void> loadUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && mounted) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      setState(() {
        userName = data['fullName'] ?? '';
      });
    }
  }

  // Initials for the profile circle (e.g. "Adrian James" -> "AJ")
  String getInitials() {
    if (userName.trim().isEmpty) return 'S';
    List<String> parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
  // Needs the userId filter and the lastStatus map. A notification only shows when
  // the status really changed. Borrowed schedules the reminder, anything else cancels it
    // Watches this student's requests and shows a notification when a status changes
  void listenToRequests() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    requestsListener = FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
            for (var doc in snapshot.docs) {
        // Ignore changes this phone has not saved to the server yet so we do not notify ourselves
        if (doc.metadata.hasPendingWrites) {
          continue;
        }
        Map<String, dynamic> data = doc.data();
        String status = data['status'] ?? 'Pending';
        String name = data['equipmentName'] ?? 'equipment';
        int reminderId = data['reminderId'] ?? 0;
        String? oldStatus = lastStatus[doc.id];

        // A real change after the first load: show a notification
        if (!firstLoad && oldStatus != null && oldStatus != status) {
          showStatusNotification(name, status);
        }

        // The return reminder only exists while the item is borrowed. Any other status cancels it
        if (status == 'Borrowed') {
          DateTime returnDate = (data['returnDate'] as Timestamp).toDate();
          scheduleReturnReminder(reminderId, name, returnDate);
        } else if (reminderId != 0) {
          cancelReminder(reminderId);
        }

        lastStatus[doc.id] = status;
      }
      firstLoad = false;
    });
  }

  @override
  void dispose() {
    requestsListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategoryName = categories[selectedCategoryIndex];
    String greeting = userName.isEmpty
        ? 'Good day'
        : 'Good day, ${userName.trim().split(' ')[0]}';

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header & Search Section
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Profile Avatar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
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
                        child: Text(
                          getInitials(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Search Bar
                  TextField(
                    // setState here is what refreshes the list while typing
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search laptop, projector, cable...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: primaryBlue),
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
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedCategoryIndex == index;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(categories[index]),
                      selected: isSelected,
                      selectedColor: primaryBlue,
                      backgroundColor: Colors.white,
                      showCheckmark: false,
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
                          selectedCategoryIndex = index;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 16),

            // Equipment Grid (data comes from Firestore)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Collection name is equipment and it is ordered by title. must match firestore
                // Empty list means check the collection name and the field names. Wrong names
                stream: FirebaseFirestore.instance
                    .collection('equipment')
                    .orderBy('title')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Could not load equipment.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryBlue),
                    );
                  }

                  // Turn documents into maps, then filter by category and search
                  List<Map<String, dynamic>> filteredEquipment = [];
                  for (var doc in snapshot.data!.docs) {
                    Map<String, dynamic> item =
                        doc.data() as Map<String, dynamic>;
                    item['id'] = doc.id;

                    bool matchesCategory = selectedCategoryName == 'All' ||
                        item['category'] == selectedCategoryName;
                    String searchText = searchQuery.toLowerCase();
                    // Search checks title and category. setState in onChanged refreshes it
                    bool matchesSearch =
                        item['title'].toString().toLowerCase().contains(searchText) ||
                            item['category'].toString().toLowerCase().contains(searchText);

                    if (matchesCategory && matchesSearch) {
                      filteredEquipment.add(item);
                    }
                  }

                  if (filteredEquipment.isEmpty) {
                    return Center(
                      child: Text(
                        'No equipment found.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: filteredEquipment.length,
                    itemBuilder: (context, index) {
                      final item = filteredEquipment[index];
                      int available = item['available'] ?? 0;
                      bool isAvailable = available > 0;
                      String imagePath = item['imagePath'] ?? '';

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
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Equipment image (from the app's assets folder)
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: EquipmentImage(
                                    key: ValueKey(imagePath),
                                    imagePath: imagePath,
                                    category: item['category'] ?? '',
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),

                              // Title
                              Text(
                                item['title'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                                                            // Category
                              Text(
                                item['category'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4),
                              // Short description (the full one is in the details page)
                              Text(
                                item['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                              SizedBox(height: 8),
                              // Availability Badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? Color(0xFFDCFCE7)
                                      : Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isAvailable
                                      ? '$available available'
                                      : 'Unavailable',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAvailable
                                        ? Color(0xFF166534)
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        // index 1 is Requests, 2 is History, 3 is Profile
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequestsPage(showHistory: false),
              ),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequestsPage(showHistory: true),
              ),
            );
          }
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          }
        },
        items: [
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