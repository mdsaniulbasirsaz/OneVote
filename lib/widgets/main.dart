import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:OneVote/widgets/Notifaction.dart';
import 'package:OneVote/widgets/PollCreate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import '../auths/adminAuthentication.dart';
import '../payment/checkout.dart';
import 'AboutUs.dart';
import 'VotingResultPage.dart';
import 'Feedback.dart';
import '../auths/userAuthentication.dart';
import 'package:OneVote/widgets/SplashScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.lightBlue),
      darkTheme: ThemeData(primarySwatch: Colors.grey),
      debugShowCheckedModeBanner: false,
      // home: HomeActivity());
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => HomeActivity(), // Your HomeActivity
      },
    );
  }
}

class HomeActivity extends StatelessWidget {
  const HomeActivity({super.key});

  // Function to fetch election data from Firestore
Future<List<Map<String, dynamic>>> fetchPollData() async {
  final snapshot = await FirebaseFirestore.instance.collection('polls').get();

  // Fetch and map the documents
  List<Map<String, dynamic>> polls = snapshot.docs.map((doc) {
    return {
      "pollId": doc.id,
      "pollTitle": doc['pollTitle'] ?? "N/A",
      "votingDescription": doc['votingDescription'] ?? "N/A",
      "startTime": (doc['startTime'] as Timestamp).toDate(),
      "endTime": (doc['endTime'] as Timestamp).toDate(),
      "createdAt": doc['createdAt'] is Timestamp
      ? (doc['createdAt'] as Timestamp).toDate()
      : DateTime.parse(doc['createdAt']),
      "isPayment": doc['isPayment'] ?? 0,
      };
  }).toList();

  List<Map<String, dynamic>> paidPolls = polls.where((poll) => poll['isPayment'] == 1).toList();
      
  // If there are paid polls, sort them by createdAt in descending order
  if (paidPolls.isNotEmpty) {
    paidPolls.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));
  }  // Filter and sort only the polls where isPayment == 1
  
  return paidPolls;
}

// Function to determine poll status
  String getPollStatus(DateTime startTime, DateTime endTime) {
    final now = DateTime.now();
    if (now.isBefore(startTime)) {
      return "Upcoming"; // Poll has not started yet
    } else if (now.isAfter(endTime)) {
      return "Completed"; // Poll has ended
    } else {
      return "Running"; // Poll is active
    }
  }

  //Function to fetch current users
  Future<DocumentSnapshot> fetchUserData() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    throw Exception("User not logged in");
  }



  // Firestore query to fetch user data
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .get();
  return userDoc;
  }

  mySnackBar(message, context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OneVote"),
        titleSpacing: 20,
        // centerTitle: true,
        backgroundColor: Colors.lightBlue,
        // toolbarHeight: 60,
        // toolbarOpacity: 1,
        // elevation: 0,
        // backgroundColor: Colors.transparent, // Transparent AppBar
        // elevation: 0, // Remove shadow
        // flexibleSpace: Container(
        //   decoration: const BoxDecoration(
        //     image: DecorationImage(
        //       image: NetworkImage(
        //         'https://img.freepik.com/premium-vector/halftone-gradient-background-with-dots-abstract-purple-dotted-pop-art-pattern-comic-style_515038-12692.jpg?ga=GA1.1.1545834930.1731245301&semt=ais_hybrid', // Replace with your image URL
        //       ),
        //       fit: BoxFit.cover, // Make the image cover the entire AppBar
        //     ),
        //   ),
        // ),
        actions: [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.comment)),
          IconButton(
              onPressed: () {
                 mySnackBar("Searching...", context);

              },
              icon: const Icon(Icons.search)),
          IconButton(
              onPressed: () {
                // mySnackBar("Notification", context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationPage()),
                );
              },
              icon: const Icon(Icons.notification_important)),

          IconButton(
              onPressed: () {
                // mySnackBar("Give me feedback", context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeedbackForm()),
                );
              },
              icon: const Icon(Icons.feedback)),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              padding: const EdgeInsets.all(0),
              decoration: const BoxDecoration(color: Colors.lightBlue),
              child: FutureBuilder<DocumentSnapshot>(
                future: fetchUserData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                    // If there's an error or no user data exists, show app name and logo
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.how_to_vote, size: 60.0, color: Colors.white),
                        SizedBox(height: 10),
                        Text(
                          'OneVote',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  }

                  // If user data exists, display it
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: userData['photo'] != null
                            ? MemoryImage(base64Decode(userData['photo'])) // Decode Base64 string
                            : null,
                        child: userData['photo'] == null
                            ? const Icon(Icons.person, size: 40, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userData['name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        userData['email'] ?? 'No Email',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.where_to_vote, color: Colors.lightBlue),
              title: const Text("Create Pole"),
              onTap: () {
                // mySnackBar("pole Page", context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PollCreatePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.lightBlue),
              title: const Text("Profile"),
              onTap: () {
                // mySnackBar("Profile Page", context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AuthenticationPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback, color: Colors.lightBlue),
              title: const Text("Feedback"),
              onTap: () {
                // mySnackBar("Feedback Page", context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeedbackForm()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_sharp,
                  color: Colors.lightBlue),
              title: const Text("Admin"),
              onTap: () {
                // mySnackBar("admin Page", context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminAuthenticationPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.lightBlue),
              title: const Text("About Us"),
              onTap: () {
                // mySnackBar("about Page", context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutUsPage()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          elevation: 10,
          backgroundColor: Colors.lightBlue.withOpacity(0.4),
          onPressed: () {
            // mySnackBar("I am floating action button", context);
             Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PollCreatePage()),
                );
          },
          child: const Icon(Icons.add)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          // BottomNavigationBarItem(icon: Icon(Icons.message), label: "Contact"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: Colors.blueGrey,
        onTap: (int index) {
          if (index == 0) {
            // mySnackBar("Home Button", context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeActivity()),
            );
          }
          // if (index == 1) {
          //   mySnackBar("Message button clicked", context);
          // }
          if (index == 1) {
            // Navigate to ProfilePage when the Profile tab is tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AuthenticationPage()),
            );
          }
        },
      ),
         body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchPollData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No poll data available.'));
          }

          final pollData = snapshot.data!;

          return SingleChildScrollView(
            child: Center(
              child: Column(
                children: pollData.map((poll) {
                  final status = getPollStatus(poll['startTime'], poll['endTime']);
                  Color statusColor;
                  String statusText;

                  // Set status color and text based on poll status
                  switch (status) {
                    case "Running":
                      statusColor = Colors.green;
                      statusText = "Running";
                      break;
                    case "Upcoming":
                      statusColor = const Color.fromARGB(255, 248, 123, 6);
                      statusText = "Upcoming";
                      break;
                    case "Completed":
                      statusColor = const Color.fromARGB(255, 248, 199, 7);
                      statusText = "Completed";
                      break;
                    default:
                      statusColor = Colors.black;
                      statusText = "Unknown";
                      break;
                  }

                  return GestureDetector(
                    onTap: () {
                      // Handle poll tap (e.g., navigate to results page)
                    },
                    child: Card(
                      margin: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Poll Title and Voting Icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  poll["pollTitle"],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(
                                  Icons.how_to_vote,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // Only display Start Time
                            Row(
                              children: [
                                    // First, display the "Start Time" label
                                  Text(
                                    "Start: ",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                   // Check if current time is before startTime
                                DateTime.now().isBefore(poll['startTime'])
                                  ? CountdownTimer(
                                      endTime: poll['startTime'].millisecondsSinceEpoch,
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        color: Color.fromARGB(255, 26, 2, 244),
                                      ),
                                      widgetBuilder: (_, time) {
                                        if (time == null) {
                                          // When countdown ends, show the start date
                                          return Text(
                                            " ${poll['startTime'].toLocal().toString().split(' ')[0]}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Color.fromARGB(255, 101, 23, 237),
                                            ),
                                          );
                                        }

                                        // While countdown is running, display the remaining time
                                        return Text(
                                          "${time.days ?? 0}d ${time.hours ?? 0}h ${time.min ?? 0}m ${time.sec ?? 0}s",
                                          style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 101, 23, 237),),
                                        );
                                      },
                                    )
                                  : Text(
                                      " ${poll['startTime'].toLocal().toString().split(' ')[0]}", // If poll has started, display the start date
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // Created At
                            Text(
                              "Created At: ${poll['createdAt']?.toLocal().toString() ?? 'N/A'}", 
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 34, 99, 239),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Description of the poll
                            Text(
                              // "Description: ${poll['votingDescription']}",
                              "Description: ${poll['votingDescription'] != null && poll['votingDescription'].isNotEmpty
                              ? (poll['votingDescription'] as String)
                                  .split(' ')  // Split the description into words
                                  .take(10)  // Take only the first 10 words
                                  .join(' ')  // Join them back into a single string
                              : ''}",  
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 15),
                            // Countdown Timer for end time
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Status Container (Running/Upcoming/Completed)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: statusColor,  // Set dynamic color based on status
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    statusText,  // Set dynamic status text (Running, Upcoming, Completed)
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // Countdown Timer (only if applicable)
                                CountdownTimer(
                                  endTime: DateTime.now().isBefore(poll['startTime']) 
                                    ? poll['startTime'].millisecondsSinceEpoch 
                                    : poll['endTime'].millisecondsSinceEpoch,
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                  widgetBuilder: (_, time) {
                                    if (time == null) {
                                      return const Text(
                                        "Time's up!",
                                        style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold, // Make it bold
                                        color: Color.fromARGB(255, 237, 6, 141),        // Set color to green
                                      ),
                                      );
                                    }

                                    return Text(
                                      "${time.days ?? 0}d ${time.hours ?? 0}h ${time.min ?? 0}m ${time.sec ?? 0}s",
                                      style: const TextStyle(fontSize: 14),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}