import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<List<Map<String, String>>> fetchYouTubeVideos(String query) async {
  final String apiKey = dotenv.env['YT_KEY']!;
  if (apiKey.isEmpty) {
    throw Exception('YouTube API key is missing.');
  }

  final Uri url = Uri.parse(
    'https://www.googleapis.com/youtube/v3/search'
    '?part=snippet'
    '&q=${Uri.encodeQueryComponent(query)}'
    '&type=video'
    '&maxResults=5'
    '&key=$apiKey',
  );

  print('YouTube API query: $query');
  print('Full URL: $url');

  final response = await http.get(url);

  print('YouTube API response: ${response.body}');

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final List items = data['items'] ?? [];
    if (items.isEmpty) {
      print('No items found in YouTube response.');
    }
    final results = items.map<Map<String, String>>((item) {
      final title = item['snippet']['title'];
      final videoId = item['id']['videoId'];
      final thumbnail = item['snippet']['thumbnails']['high']['url'];
      final link = 'https://www.youtube.com/watch?v=$videoId';

      return {'title': title, 'thumbnail': thumbnail, 'link': link};
    }).toList();

    return results;
  } else {
    throw Exception(
      'Failed to fetch videos. Status code: ${response.statusCode}',
    );
  }
}

// Usage:
//   final videos = await fetchYouTubeVideos(nextSubtopic);
//   // nextSubtopic is a string, e.g. "Android Intents" or any subtopic name
