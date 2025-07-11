import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<String> _getUsername(User user) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data != null &&
        data['username'] != null &&
        data['username'].toString().trim().isNotEmpty) {
      return data['username'];
    }
    return user.uid;
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("No user is currently signed in."));
    }
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
              FutureBuilder<String>(
                future: _getUsername(user),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  return Text(
                    snapshot.data ?? user.uid,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                user.email ?? 'No email available',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
