import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_manager/screens/adminchatview.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    QuerySnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    List<Map<String, dynamic>> users = userSnapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    }).toList();

    return users;
  }

  Future<List<String>> fetchUserChatIds(String userId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chats')
        .get(const GetOptions(source: Source.server)); // Ensure fresh fetch

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      appBar: AppBar(
        title: const Text('Users with Chats'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.red,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          List<Map<String, dynamic>> users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  title: Text(user['username'] ?? 'Unnamed User'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${user['email'] ?? 'No Email'}'),
                      Text('Contact: ${user['contact'] ?? 'No Contact'}'),
                    ],
                  ),
                  children: [
                    FutureBuilder<List<String>>(
                      future: fetchUserChatIds(user['id']),
                      builder: (context, chatSnapshot) {
                        if (chatSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (chatSnapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Error: ${chatSnapshot.error}'),
                          );
                        }

                        List<String> chatIds = chatSnapshot.data ?? [];
                        if (chatIds.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No chats available'),
                          );
                        }

                        return Column(
                          children: chatIds.map((chatId) {
                            return ListTile(
                              title: Text('Chat ID: $chatId'),
                              subtitle: const Text('Tap to view messages'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => AdminChatView(
                                      userId: user['id'],
                                      chatId: chatId,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
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
