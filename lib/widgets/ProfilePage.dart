import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/Login.dart'; // Your Login Page
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'EditProfile.dart';
import 'dart:convert';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    try{
      final user = FirebaseAuth.instance.currentUser;
      if(user!=null)
      {
        //Fetch user data from Firestore
         DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
            .instance
            .collection('users') // Assuming user data is stored in 'users' collection
            .doc(user.uid)
            .get();
        return userDoc.data();
      }
    } catch(e) {
      debugPrint("Error fetching user data: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth instance for sign-out
    final FirebaseAuth _auth = FirebaseAuth.instance;

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
          if(snapshot.connectionState == ConnectionState.waiting) {
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
          final userEmail = userData?['email'] ?? 'No Email'; // Set fallback value
          final userMobile = userData?['number'] ?? 'No Mobile'; // Set fallback value
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
                                  image: MemoryImage(base64Decode(userProfilePhoto)),  // Decode Base64
                                  fit: BoxFit.cover,
                                )
                              : null,  // Handle case when there's no photo
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                              await _auth.signOut();

                              // After sign out, navigate to login page
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const Login()),
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
                            backgroundColor: const Color(0xFF1877F2),
                            // Facebook blue color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Adjust the rounding
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
                                  builder: (context) => EditProfilePage(userData: userData!),
                                ),
                              );
                            },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1877F2),
                            // Facebook blue color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Adjust the rounding
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 10.0),
                  Card(
                    child: Table(
                      border: TableBorder.all(),
                      children: const [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.lightBlueAccent),
                          children: [
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
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Election 2023'),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Jan 1, 2023'),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                '200 BDT',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Election 2024'),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Feb 15, 2024'),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                '100 BDT',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        // Add more rows as needed
                      ],
                    ),
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