import 'dart:convert';
import 'package:http/http.dart' as http;

const String _geminiApiKey = '';
const String _geminiEndpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

Future<List<Map<String, dynamic>>> generateQuizFromTopics(List<String> topics) async {
  final String topicPrompt = topics.join(', ');
  final String prompt = '''
You are an expert quiz generator.

🎯 Generate **exactly 10 multiple-choice questions** based on the following topics:
$topicPrompt

🧠 Format the response as a **JSON array** like below:

[
  {
    "q": "What is 1+1 in boolean?",
    "a": "-1",
    "b": "0",
    "c": "1",
    "d": "2",
    "co": "c"
  },
  {
    "q": "...",
    "a": "...",
    "b": "...",
    "c": "...",
    "d": "...",
    "co": "b"
  }
]

💡 Notes:
- `q` is the question
- `a`, `b`, `c`, `d` are answer options
- `co` is the correct answer label ("a" / "b" / "c" / "d")
- Make sure the JSON is valid and parseable.
''';

  final response = await http.post(
    Uri.parse('$_geminiEndpoint?key=$_geminiApiKey'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.7,
        "topK": 40,
        "topP": 0.9,
        "maxOutputTokens": 2048
      }
    }),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> json = jsonDecode(response.body);
    final candidates = json['candidates'];
    if (candidates != null && candidates.isNotEmpty) {
      final content = candidates[0]['content'];
      final parts = content['parts'];
      final responseText = parts.map((p) => p['text']).join().trim();

      try {
        // Parse the JSON block from response text
        final quizData = jsonDecode(responseText);
        if (quizData is List) {
          return List<Map<String, dynamic>>.from(quizData);
        } else {
          throw Exception("Parsed data is not a List.");
        }
      } catch (e) {
        print("❌ JSON parsing error: $e");
        print("Response text: $responseText");
        return [];
      }
    }
  } else {
    print('❌ Error from Gemini: ${response.statusCode}');
    print(response.body);
  }

  return [];
}

//void main() async {
//  final topics = ['Operating Systems', 'Concurrency', 'Process Scheduling'];
//  final quiz = await generateQuizFromTopics(topics);
//
//  for (final q in quiz) {
//    print(q['q']);
//    print("A: ${q['a']}, B: ${q['b']}, C: ${q['c']}, D: ${q['d']}");
//    print("Correct: ${q['co']}\n");
//  }
//}
//
