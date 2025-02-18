import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({Key? key}) : super(key: key);

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  late Future<DocumentSnapshot?> _profileData;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _profileData = fetchProfileData();
  }

  Future<DocumentSnapshot?> fetchProfileData() async {
    // Get the currently logged-in user
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return null; // No user logged in
    }

    final email = currentUser.email;

    // Query Firestore to fetch the user profile by email
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email) // Match the logged-in user's email
        .get();

    // If a matching document exists, return it
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first; // Return the first matching document
    }

    return null; // No matching document found
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final headingColor = isDarkTheme ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
        backgroundColor: Colors.red,
      ),
      backgroundColor: isDarkTheme ? Colors.black : Colors.white,
      body: FutureBuilder<DocumentSnapshot?>(
        future: _profileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading profile data.'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profile not found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileField(
                  heading: 'Username',
                  value: userData['username'] ?? 'N/A',
                  textColor: textColor,
                  headingColor: headingColor,
                ),
                ProfileField(
                  heading: 'Email',
                  value: userData['email'] ?? 'N/A',
                  textColor: textColor,
                  headingColor: headingColor,
                ),
                ProfileField(
                  heading: 'Name',
                  value: userData['name'] ?? 'N/A',
                  textColor: textColor,
                  headingColor: headingColor,
                ),
                ProfileField(
                  heading: 'Contact',
                  value: userData['contact'] ?? 'N/A',
                  textColor: textColor,
                  headingColor: headingColor,
                ),
                ProfileField(
                  heading: 'Bank Details',
                  value: userData['bankdetails'] ?? 'N/A',
                  textColor: textColor,
                  headingColor: headingColor,
                ),
                ProfileField(
                  heading: 'Account No',
                  value: userData['accountno'] ?? 'N/A',
                  textColor: textColor,
                  headingColor: headingColor,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ProfileField extends StatelessWidget {
  final String heading;
  final String value;
  final Color textColor;
  final Color headingColor;

  const ProfileField({
    Key? key,
    required this.heading,
    required this.value,
    required this.textColor,
    required this.headingColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          Expanded(
            flex: 3,
            child: Text(
              heading,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: headingColor,
              ),
            ),
          ),
          // Value
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
