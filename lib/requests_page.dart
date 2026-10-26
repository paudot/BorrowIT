import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'helpers.dart';
import 'photo_helper.dart';
import 'borrow_request_page.dart';
import 'return_page.dart';

class RequestsPage extends StatelessWidget {
  final bool showHistory;

  const RequestsPage({super.key, required this.showHistory});

  static const Color primaryBlue = Color(0xFF1E40AF);

  // Time used to sort newest first
  DateTime getTime(QueryDocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Timestamp? created = data['createdAt'] as Timestamp?;
    return created == null ? DateTime.now() : created.toDate();
  }

  // Cancel a pending request (deletes it from Firestore and its photo from the phone)
  void confirmCancel(BuildContext context, String requestId, String name) {
    ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cancel request'),
        content: Text('Cancel your request for $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Keep'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await FirebaseFirestore.instance
                    .collection('requests')
                    .doc(requestId)
                    // Firestore rules only allow deleting Pending requests
                    .delete();
                await deletePhotos(requestId);
                messenger.showSnackBar(
                  SnackBar(content: Text('Request cancelled.')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Could not cancel the request.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Cancel request', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          showHistory ? 'Borrowing History' : 'My Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: user == null
          ? Center(child: Text('No user logged in.'))
          : StreamBuilder<QuerySnapshot>(
              // Only this student's requests
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  // Without this filter or with a wrong field name the list is empty
                  .where('userId', isEqualTo: user.uid) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Could not load your requests.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  );
                }

                // History = Returned, Requests = everything else
                List<QueryDocumentSnapshot> requests = [];
                for (var doc in snapshot.data!.docs) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  // History shows Returned only, My Requests shows everything else.
                  // Status text must match exactly: Pending, Approved, Borrowed, Returned
                  bool isReturned = data['status'] == 'Returned';
                  if (isReturned == showHistory) {
                    requests.add(doc);
                  }
                }
                requests.sort((a, b) => getTime(b).compareTo(getTime(a)));

                // Empty state
                if (requests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            showHistory ? Icons.history : Icons.article_outlined,
                            size: 64,
                            color: primaryBlue,
                          ),
                          SizedBox(height: 12),
                          Text(
                            showHistory
                                ? 'No borrowing history yet'
                                : 'No requests yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            showHistory
                                ? 'Returned equipment will show up here.'
                                : 'Pick an equipment and send your first request.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(20),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    QueryDocumentSnapshot doc = requests[index];
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    String status = data['status'] ?? 'Pending';
                    DateTime dateNeeded = (data['dateNeeded'] as Timestamp).toDate();
                    DateTime returnDate = (data['returnDate'] as Timestamp).toDate();

                    bool showAfterPhoto = status == 'Returned';

                    return Container(
                      margin: EdgeInsets.only(bottom: 14),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and status
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: EquipmentImage(
                                  key: ValueKey(data['imagePath'] ?? ''),
                                  imagePath: data['imagePath'] ?? '',
                                  category: data['category'] ?? '',
                                  iconSize: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['equipmentName'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      data['category'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBackground(status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusTextColor(status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Divider(height: 1, color: Color(0xFFF1F5F9)),
                          SizedBox(height: 12),

                          // Dates
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 16, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${formatDate(dateNeeded)}  to  ${formatDate(returnDate)}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),

                          // Purpose
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.edit_note_outlined,
                                  size: 18, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['purpose'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Note written when the item was returned
                          if ((data['returnNote'] ?? '').toString().isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.notes_outlined,
                                      size: 18, color: Colors.grey[600]),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Return note: ${data['returnNote']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 14),

                          // Before and after photos (saved on the phone)

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: PhotoBox(
                                  key: ValueKey('${doc.id}_before'),
                                  requestId: doc.id,
                                  type: 'before',
                                ),
                              ),
                              if (showAfterPhoto) SizedBox(width: 12),
                              if (showAfterPhoto)
                                Expanded(
                                  child: PhotoBox(
                                    key: ValueKey('${doc.id}_after'),
                                    requestId: doc.id,
                                    type: 'after',
                                  ),
                                ),
                            ],
                          ),
                          // Edit and Cancel need status Pending, the Return button needs Borrowed
                          // Only pending requests can be edited or cancelled
                          if (status == 'Pending')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Map<String, dynamic> item = {
                                      'id': data['equipmentId'],
                                      'title': data['equipmentName'],
                                      'category': data['category'],
                                      'imagePath': data['imagePath'],
                                    };
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BorrowRequestPage(
                                          item: item,
                                          requestId: doc.id,
                                          existing: data,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text('Edit'),
                                ),
                                TextButton(
                                  onPressed: () => confirmCancel(context, doc.id,
                                      data['equipmentName'] ?? ''),
                                                                    child: Text(
                                    'Cancel request',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),

                          // Borrowed items can be returned
                          if (status == 'Borrowed') SizedBox(height: 12),
                          if (status == 'Borrowed')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReturnPage(
                                          requestId: doc.id,
                                          request: data,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('Return item'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}