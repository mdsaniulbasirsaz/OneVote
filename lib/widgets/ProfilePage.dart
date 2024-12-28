import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/Login.dart'; // Your Login Page
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'EditProfile.dart';
import 'dart:convert';
import 'package:intl/intl.dart';



class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Fetch Polls from Firestore
  Future<List<Map<String, dynamic>>> fetchPolls(String name) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('polls').where('createdBy', isEqualTo: name).get();

      List<Map<String, dynamic>> polls = snapshot.docs.map((doc) {
        return {
          "paymentAmount": doc['paymentAmount'],
          "pollId": doc['pollId'],
          "pollTitle": doc['pollTitle'],
          "createdAt": doc['createdAt'],
          "isPayment": doc['isPayment'] ?? 0,
        };
      }).toList();

      List<Map<String, dynamic>> paidPolls = polls.where((poll) => poll['isPayment'] == 1).toList();
      
      // If there are paid polls, sort them by createdAt in descending order
      if (paidPolls.isNotEmpty) {
        paidPolls.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
      }  // Filter and sort only the polls where isPayment == 1
      return paidPolls;
    
    } catch (e) {
      print('Error fetching polls: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        //Fetch user data from Firestore
        DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
            .instance
            .collection(
                'users') // Assuming user data is stored in 'users' collection
            .doc(user.uid)
            .get();
        return userDoc.data();
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth instance for sign-out
    final FirebaseAuth auth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.lightBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeActivity()),
            );
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading profile data."),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Text("No user data found."),
            );
          }

          final userData = snapshot.data;
          final userName = userData?['name'] ?? 'No Name'; // Set fallback value
          final userEmail =
              userData?['email'] ?? 'No Email'; // Set fallback value
          final userMobile =
              userData?['number'] ?? 'No Mobile'; // Set fallback value
          final userProfilePhoto = userData?['photo'] ?? 'No Photo';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  Center(
                    child: ClipOval(
                      child: Container(
                        width: 100.0, // Adjust the width and height as needed
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
                  const SizedBox(height: 16.0),

                  // Profile Name Card
                  Card(
                    color: Colors.white,
                    child: ListTile(
                      title: const Text(
                        "Name",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(userName),
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // Mobile Number Card
                  Card(
                    color: Colors.white,
                    child: ListTile(
                      title: const Text(
                        "Mobile",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(userMobile),
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // Email Card
                  Card(
                    color: Colors.white,
                    child: ListTile(
                      title: const Text(
                        "Email",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(userEmail),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Logout and Edit Profile Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logout Button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              // Sign out the user
                              await auth.signOut();

                              // After sign out, navigate to login page
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Login()),
                              );
                            } catch (e) {
                              // Handle any errors
                              print("Error signing out: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Logout failed!")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            // Facebook blue color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8), // Adjust the rounding
                            ),
                          ),
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.white, // Icon color
                          ),
                          label: const Text(
                            "Logout",
                            style: TextStyle(color: Colors.white), // Text color
                          ),
                        ),
                      ),

                      // Add some spacing between the buttons
                      const SizedBox(width: 16),

                      // Edit Profile Button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Add Edit Profile functionality here
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditProfilePage(userData: userData!),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1877F2),
                            // Facebook blue color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8), // Adjust the rounding
                            ),
                          ),
                          icon: const Icon(
                            Icons.edit, // Icon for Edit Profile
                            color: Colors.white, // Icon color
                          ),
                          label: const Text(
                            "Edit Profile",
                            style: TextStyle(color: Colors.white), // Text color
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20.0),
                  const Divider(height: 10, thickness: 1),
                  // Voting Service Table
                  const Center(
                    child: Text(
                      "Voting Services",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 10.0),
                  // Fetch Polls and show in Table
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchPolls(userName),
                    builder: (context, pollSnapshot) {
                      if (pollSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (pollSnapshot.hasError) {
                        return const Center(
                          child: Text("Error loading polls data."),
                        );
                      }
                      if (!pollSnapshot.hasData || pollSnapshot.data!.isEmpty) {
                        return const Center(
                          child: Text("No paid polls available."),
                        );
                      }

                      // Extracting poll data for table display
                      List<Map<String, dynamic>> polls = pollSnapshot.data!;

                      return Card(
                        child: Table(
                          border: TableBorder.all(),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: Colors.lightBlueAccent),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Poll ID',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Title',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Date',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Amount',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            // Populate table rows dynamically
                            ...polls.map((poll) {
                              // Ensure createdAt is a DateTime object
                              DateTime createdAt = poll['createdAt'] is Timestamp
                                  ? (poll['createdAt'] as Timestamp).toDate()
                                  : DateTime.parse(poll['createdAt'].toString());

                              String formattedDate = DateFormat('yMd').add_jm().format(createdAt);

                              
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(poll['pollId'],
                                    style: TextStyle(fontSize: 9),),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(poll['pollTitle'],
                                    style: TextStyle(fontSize: 9),),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      formattedDate,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 9),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '${poll['paymentAmount']} BDT',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 9),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}