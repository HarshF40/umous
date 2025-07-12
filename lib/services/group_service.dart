import 'package:cloud_firestore/cloud_firestore.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // TODO: Add methods for group creation, joining, fetching, leaderboard, etc.

  Future<void> createGroup({
    required String groupName,
    required String adminUid,
    required String adminEmail,
    required List<String> invitedEmails,
    required String topic,
  }) async {
    final groupRef = _firestore.collection('groups').doc();
    final groupId = groupRef.id;
    await groupRef.set({
      'name': groupName,
      'adminUid': adminUid,
      'adminEmail': adminEmail,
      'members': [adminUid],
      'invites': invitedEmails,
      'topic': topic,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Add group to admin's user groups subcollection
    await _firestore
        .collection('users')
        .doc(adminUid)
        .collection('groups')
        .doc(groupId)
        .set({'name': groupName, 'joinedAt': FieldValue.serverTimestamp()});
  }

  Future<void> acceptInvite({
    required String groupId,
    required String uid,
  }) async {
    final user = await _firestore.collection('users').doc(uid).get();
    final userEmail = user.data()?['email'] ?? '';

    // Add user to group members
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([uid]),
      'invites': FieldValue.arrayRemove([userEmail]),
    });

    // Get group name and add to user's groups
    final group = await _firestore.collection('groups').doc(groupId).get();
    final groupName = group.data()?['name'] ?? 'Unnamed Group';

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('groups')
        .doc(groupId)
        .set({'name': groupName, 'joinedAt': FieldValue.serverTimestamp()});
  }

  Future<void> declineInvite({
    required String groupId,
    required String email,
  }) async {
    await _firestore.collection('groups').doc(groupId).update({
      'invites': FieldValue.arrayRemove([email]),
    });
  }

  Future<void> leaveGroup({
    required String groupId,
    required String uid,
  }) async {
    // Remove user from group members
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayRemove([uid]),
    });

    // Remove group from user's groups subcollection
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('groups')
        .doc(groupId)
        .delete();
  }

  Future<void> inviteMember({
    required String groupId,
    required String email,
  }) async {
    await _firestore.collection('groups').doc(groupId).update({
      'invites': FieldValue.arrayUnion([email]),
    });
  }
}
