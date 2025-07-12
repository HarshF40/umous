import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

final String _geminiApiKey = dotenv.env['GEMINI_KEY']!;
const String _geminiEndpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

Future<bool> handleNewTopic(String topic) async {
  print('New topic: $topic');

  final String prompt =
      '''
You are an expert roadmap creator for developers. Your task is to generate a **detailed, comma-separated, progressive roadmap** for the topic: "$topic".

📌 Format: One single string with each step separated by commas (not lists or paragraphs).

📌 Structure:
- Start with fundamental concepts, then build up to advanced topics.
- Include essential tools, libraries, frameworks, protocols, and best practices.
- Group related concepts logically.
- Be exhaustive but not redundant.
- Follow the style and depth shown in the examples below.

✅ Example — For topic "frontend":
Internet, How does the internet work?, What is HTTP?, What is Domain Name?, What is hosting?, DNS and how it works?, Browsers and how they work?, HTML, Learn the basics, Writing Semantic HTML, Forms and Validations, Accessibility, SEO Basics, CSS, Learn the basics, Making Layouts, Responsive Design, JavaScript, Learn the Basics, Learn DOM Manipulation, Fetch API / Ajax (XHR), Version Control Systems, Git, VCS Hosting, GitHub, GitLab, Bitbucket, Package Managers, npm, yarn, pnpm, Pick a Framework, React, Angular, Vue.js, Svelte, Solid JS, Qwik, Writing CSS, Tailwind, CSS Architecture, CSS Preprocessors, Sass, PostCSS, BEM, Build Tools, Module Bundlers, Webpack, Vite, esbuild, Rollup, Parcel, Linters and Formatters, ESLint, Prettier, Testing, Jest, Vitest, Cypress, Playwright, Type Checkers, TypeScript, Authentication Strategies, JWT, OAuth, SSO, Basic Auth, Session Auth, Web Security Basics, HTTPS, CORS, Content Security Policy, OWASP Security Risks, Web Components, Custom Elements, HTML Templates, Shadow DOM, SSR, Next.js, Nuxt.js, Svelte Kit, GraphQL, Apollo, Relay Modern, Static Site Generators, Astro, Eleventy, Vuepress, PWAs, Service Workers, Web Sockets, Server Sent Events, Browser APIs, Storage, Location, Notifications, Device Orientation, Payments, Credentials, Performance Metrics, Using Lighthouse, Using DevTools, Performance Best Practices, PRPL Pattern, RAIL Model, Mobile Apps, React Native, Flutter, Ionic, Desktop Apps, Electron, Tauri

Return the roadmap for "$topic" in the **exact same comma-separated format**.
''';

  final response = await http.post(
    Uri.parse('$_geminiEndpoint?key=$_geminiApiKey'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
      "generationConfig": {
        "temperature": 0.6,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 2048,
      },
    }),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> json = jsonDecode(response.body);
    final candidates = json['candidates'];
    if (candidates != null && candidates.isNotEmpty) {
      final content = candidates[0]['content'];
      final parts = content['parts'];
      final roadmapText = parts.map((p) => p['text']).join().trim();
      // send to firebase and return true
      // ✅ Get the existing document
      final docRef = FirebaseFirestore.instance
          .collection('roadmaps')
          .doc('topics');

      final docSnapshot = await docRef.get();

      final currentFields = docSnapshot.data();
      final nextId = currentFields == null
          ? "1"
          : (currentFields.length + 1).toString();

      // ✅ Add new field to the existing map
      await docRef.set({
        nextId: {topic: roadmapText},
      }, SetOptions(merge: true));

      print("✅ Roadmap for '$topic' added under field: $nextId");
      return true;
    } else {
      print("⚠️ Gemini returned no candidates.");
      return false;
    }
  } else {
    print('❌ Error: ${response.statusCode}');
    print(response.body);
    return false;
  }
}
