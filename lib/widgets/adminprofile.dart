import 'dart:convert';

import 'package:OneVote/widgets/price.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'adminLoginPage.dart';
import 'adminfeedback.dart';
import 'notice.dart';

class AdminProfile extends StatelessWidget {
  final double totalIncome;

  const AdminProfile({super.key, this.totalIncome = 0.0});


  // Fetch Polls from Firestore
  Future<List<Map<String, dynamic>>> fetchPolls() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('polls').get();

      List<Map<String, dynamic>> polls = snapshot.docs.map((doc) {
        return {
          "paymentAmount": doc['paymentAmount'],
          "createdBy": doc['createdBy'],
          "createdAt": doc['createdAt'],
          "isPayment": doc['isPayment'] ?? 0,
        };
      }).toList();

      polls.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
      return polls;
    } catch (e) {
      print('Error fetching polls: $e');
      return [];
    }
  }





  Future<Map<String, dynamic>?> _fetchUserData() async {
    try {
      // Get the current user's UID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Fetch user data from Firestore
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  Future<String> _fetchUserProfilePicture() async {
    try {
      // Get the current user's UID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return ''; // Return an empty string if no user is found

      // Check if the photo URL is stored in Firestore first
      final userData = await _fetchUserData();
      String profilePictureUrl = userData?['photo'] ?? '';

      if (profilePictureUrl.isEmpty) {
        // If photo URL is not found in Firestore, check Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures/${user.uid}.jpg');
        profilePictureUrl = await storageRef.getDownloadURL();
      }

      return profilePictureUrl;
    } catch (e) {
      print("Error fetching profile picture: $e");
      return ''; // Return empty if there's an error
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Profile"),
        backgroundColor: Colors.lightBlue,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final userData = snapshot.data;
          final name = userData?['name'] ?? 'Admin Name';
          final email = userData?['email'] ?? 'admin@example.com';
          // final userProfilePhoto = userData?['photo'] ?? 'No Photo';

          return FutureBuilder<String>(
            future: _fetchUserProfilePicture(),
            builder: (context, pictureSnapshot) {
              if (pictureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final userProfilePhoto = pictureSnapshot.data ?? '';

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Profile picture and information
                      Center(
                        child: ClipOval(
                          child: Container(
                            width: 100.0,
                            // Adjust the width and height as needed
                            height: 100.0,
                            decoration: BoxDecoration(
                              image: userProfilePhoto != 'No Photo'
                                  ? DecorationImage(
                                      image: MemoryImage(
                                          base64Decode(userProfilePhoto)),
                                      // Decode Base64
                                      fit: BoxFit.cover,
                                    )
                                  : null, // Handle case when there's no photo
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    name,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.email, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    email,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 10, thickness: 1),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to the Feedback page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const AdminFeedBack()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1877F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.feedback,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "See Feedback",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Handle total income functionality here
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1877F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.payments,
                              color: Colors.white,
                            ),
                            label: Text(
                              "Total: ৳${totalIncome.toStringAsFixed(2)}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Price()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1877F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.price_change,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Set Price",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => InputPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1877F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(
                              Icons.notification_add,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Add Notification",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Perform Firebase sign-out
                          try {
                            await FirebaseAuth.instance.signOut();
                            // Redirect to login page after sign-out
                            Navigator.pushReplacement(
                              // ignore: use_build_context_synchronously
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Admin()),
                            );
                          } catch (e) {
                            // print("Error signing out: $e");
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Logout failed!")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const Divider(height: 20, thickness: 1),
                      const Center(
                        child: Text(
                          "Service List",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: fetchPolls(),
                        builder: (context, pollSnapshot) {
                          if (pollSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (pollSnapshot.hasError) {
                            return Center(child: Text('Error: ${pollSnapshot.error}'));
                          }

                          final polls = pollSnapshot.data ?? [];

                          if (polls.isEmpty) {
                            return Center(child: Text('No data available'));
                          }

                      // Calculate total payment amount
                          double totalPaymentAmount = 0.0;
                          for (var poll in polls) {
                            String paymentAmountString = poll['paymentAmount'] ?? '0.0';  // Default to '0.0' if null
                            double paymentAmount = double.tryParse(paymentAmountString) ?? 0.0;  // Safely parse to double
                            totalPaymentAmount += paymentAmount;
                          }

                          return Column(
                            children: [
                              // Display Total Payment Amount
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Total Earning: ${totalPaymentAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue, // Set the text color to blue (you can change it to any color you like)
                                    ),
                                  ),
                                ),
                              Card(
                                child: Table(
                                  border: TableBorder.all(),
                                  children: [
                                    const TableRow(
                                      decoration: BoxDecoration(color: Color(0xFF1877F2)),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Center(child: Text('Name', style: TextStyle(color: Colors.white))),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Center(child: Text('Created Date', style: TextStyle(color: Colors.white))),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Center(child: Text('Earning', style: TextStyle(color: Colors.white))),
                                        ),
                                      ],
                                    ),
                                    ...polls.map((poll) {
                                      // Ensure createdAt is a DateTime object
                                      DateTime createdAt = poll['createdAt'] is Timestamp
                                          ? (poll['createdAt'] as Timestamp).toDate()
                                          : DateTime.parse(poll['createdAt'].toString());

                                      return TableRow(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200], // Add background color for each row
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              poll['createdBy'] ?? 'Unknown',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              DateFormat.yMd().add_jm().format(createdAt),
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Center(
                                              child: Text(
                                                poll['isPayment'] == 1
                                                    ? (poll['paymentAmount'] != null
                                                        ? poll['paymentAmount'].toString()
                                                        : 'N/A')
                                                    : 'Not completed',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: poll['isPayment'] == 1
                                                      ? const Color.fromARGB(255, 20, 166, 1)
                                                      : (poll['isPayment'] == 0
                                                          ? Colors.red
                                                          : const Color.fromARGB(255, 157, 3, 246)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}