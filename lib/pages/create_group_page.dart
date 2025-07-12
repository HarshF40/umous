import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/group_service.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({Key? key}) : super(key: key);

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _inviteEmailController = TextEditingController();
  final List<String> _invitedEmails = [];
  bool _loading = false;
  List<String> _topics = [];
  String? _selectedTopic;
  bool _topicsLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    setState(() => _topicsLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('roadmaps')
          .doc('topics')
          .get();
      if (!doc.exists || doc.data() == null) {
        setState(() {
          _topics = [];
          _selectedTopic = null;
          _topicsLoading = false;
        });
        return;
      }
      final data = doc.data()!;
      final topics = data.values
          .map((e) => (e as Map).keys.first.toString().trim())
          .toSet()
          .toList(); // deduplicate
      topics.sort();
      String? newSelected = _selectedTopic;
      if (newSelected == null || !topics.contains(newSelected)) {
        newSelected = null;
      }
      setState(() {
        _topics = topics;
        _selectedTopic = newSelected;
        _topicsLoading = false;
      });
    } catch (e) {
      setState(() {
        _topics = [];
        _selectedTopic = null;
        _topicsLoading = false;
      });
    }
  }

  void _addInvite() {
    final email = _inviteEmailController.text.trim();
    if (email.isNotEmpty && !_invitedEmails.contains(email)) {
      setState(() {
        _invitedEmails.add(email);
        _inviteEmailController.clear();
      });
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate() || _selectedTopic == null) return;
    setState(() => _loading = true);
    final groupName = _groupNameController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await GroupService().createGroup(
        groupName: groupName,
        adminUid: user.uid,
        adminEmail: user.email ?? '',
        invitedEmails: _invitedEmails,
        topic: _selectedTopic!,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create group: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter group name' : null,
              ),
              const SizedBox(height: 20),
              _topicsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedTopic,
                      items: _topics
                          .map(
                            (topic) => DropdownMenuItem(
                              value: topic,
                              child: Text(topic),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedTopic = val),
                      decoration: const InputDecoration(
                        labelText: 'Select Group Topic',
                      ),
                      validator: (v) => v == null ? 'Select a topic' : null,
                    ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _inviteEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Invite by email',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addInvite,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: _invitedEmails
                    .map(
                      (email) => Chip(
                        label: Text(email),
                        onDeleted: () {
                          setState(() => _invitedEmails.remove(email));
                        },
                      ),
                    )
                    .toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _createGroup,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Create Group'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
