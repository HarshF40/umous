import 'package:flutter/material.dart';
import '../utilities/topics.dart';

class ChooseTopicsPage extends StatefulWidget {
  final List<String> selectedTopics;
  const ChooseTopicsPage({super.key, required this.selectedTopics});

  @override
  State<ChooseTopicsPage> createState() => _ChooseTopicsPageState();
}

class _ChooseTopicsPageState extends State<ChooseTopicsPage> {
  late List<String> _chosen;

  @override
  void initState() {
    super.initState();
    _chosen = List<String>.from(widget.selectedTopics);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Topics')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select up to 4 topics:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: allTopics.map((topic) {
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
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
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
    );
  }
}
