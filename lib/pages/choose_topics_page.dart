import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utilities/topic_utils.dart';

class ChooseTopicsPage extends StatefulWidget {
  final List<String> selectedTopics;
  const ChooseTopicsPage({super.key, required this.selectedTopics});

  @override
  State<ChooseTopicsPage> createState() => _ChooseTopicsPageState();
}

class _ChooseTopicsPageState extends State<ChooseTopicsPage> {
  late List<String> _chosen;
  List<String> _topics = [];
  bool _loading = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _chosen = widget.selectedTopics.map((e) => e.trim()).toList();
    fetchTopics();
  }

  Future<void> fetchTopics() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('roadmaps')
          .doc('topics')
          .get();
      if (!doc.exists || doc.data() == null) {
        setState(() {
          _topics = [];
          _loading = false;
        });
        return;
      }
      final data = doc.data()!;
      final topics = data.values
          .map((e) => (e as Map).keys.first.toString().trim())
          .toList();
      topics.sort();
      setState(() {
        _topics = topics;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading topics';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Topics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : (_topics.isEmpty)
                  ? const Center(child: Text('No topics found.'))
                  : Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Select up to 4 topics:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _topics.length,
                                  itemBuilder: (context, index) {
                                    final topic = _topics[index].trim();
                                    final selected = _chosen.contains(topic);
                                    return CheckboxListTile(
                                      title: Text(topic),
                                      value: selected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            if (_chosen.length < 4) {
                                              _chosen.add(topic);
                                            }
                                          } else {
                                            _chosen.remove(topic);
                                          }
                                        });
                                      },
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                    );
                                  },
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context, _chosen);
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        ),
                        if (_saving)
                          Container(
                            color: Colors.black.withOpacity(0.4),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTopicDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add New Topic',
      ),
    );
  }

  void _showAddTopicDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Topic'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter topic name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTopic = controller.text.trim();
              if (newTopic.isNotEmpty) {
                handleNewTopic(newTopic);
              }
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 100));
              setState(() {
                _saving = true;
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
