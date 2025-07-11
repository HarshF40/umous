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
      // Filter _chosen to only include topics that exist in _topics
      final filteredChosen = _chosen.where((t) => topics.contains(t)).toList();
      setState(() {
        _topics = topics;
        _chosen = filteredChosen;
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
                              Text(
                                'Select up to 4 topics: (${_chosen.length}/4)',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _topics.length,
                                  itemBuilder: (context, index) {
                                    final topic = _topics[index];
                                    final selected = _chosen.contains(topic);
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: CheckboxListTile(
                                        key: ValueKey(topic),
                                        title: Text(topic),
                                        value: selected,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              if (_chosen.length < 4) {
                                                _chosen.add(topic);
                                              } else {
                                                // Show message when limit reached
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Maximum 4 topics allowed'),
                                                    duration:
                                                        Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            } else {
                                              _chosen.remove(topic);
                                            }
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      ),
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
            onPressed: () {
              final newTopic = controller.text.trim();
              if (newTopic.isNotEmpty) {
                // Add the new topic to the local list
                setState(() {
                  _topics.add(newTopic);
                  _topics.sort();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Topic "$newTopic" added successfully')),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _TopicCheckbox extends StatelessWidget {
  final String topic;
  final bool selected;
  final ValueChanged<bool?> onChanged;
  const _TopicCheckbox(
      {required this.topic, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(topic),
      value: selected,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
