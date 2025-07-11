//import 'dart:convert';
//import 'package:http/http.dart' as http;
//
//Future<void> fetchYouTubeVideos(String query) async {
//  const String apiKey = '';
//  final Uri url = Uri.parse(
//    'https://www.googleapis.com/youtube/v3/search'
//    '?part=snippet'
//    '&q=${Uri.encodeQueryComponent(query)}'
//    '&type=video'
//    '&maxResults=5'
//    '&key=$apiKey',
//  );
//
//  final response = await http.get(url);
//
//  if (response.statusCode == 200) {
//    final data = json.decode(response.body);
//
//    final List items = data['items'];
//    for (var item in items) {
//      final title = item['snippet']['title'];
//      final videoId = item['id']['videoId'];
//      final thumbnail = item['snippet']['thumbnails']['high']['url'];
//      final link = 'https://www.youtube.com/watch?v=$videoId';
//
//      print('Title: $title');
//      print('Thumbnail: $thumbnail');
//      print('Link: $link\n');
//    }
//  } else {
//    print('Failed to fetch videos. Status code: ${response.statusCode}');
//  }
//}

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetch top 5 YouTube videos for a given search query.
/// Returns a List of Maps containing 'title', 'thumbnail', and 'link'.
Future<List<Map<String, String>>> fetchYouTubeVideos(String query) async {
  const String apiKey = ''; // Replace with your actual API key

  final Uri url = Uri.parse(
    'https://www.googleapis.com/youtube/v3/search'
    '?part=snippet'
    '&q=${Uri.encodeQueryComponent(query)}'
    '&type=video'
    '&maxResults=5'
    '&key=$apiKey',
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final List items = data['items'];

    final results = items.map<Map<String, String>>((item) {
      final title = item['snippet']['title'];
      final videoId = item['id']['videoId'];
      final thumbnail = item['snippet']['thumbnails']['high']['url'];
      final link = 'https://www.youtube.com/watch?v=$videoId';

      return {
        'title': title,
        'thumbnail': thumbnail,
        'link': link,
      };
    }).toList();

    return results;
  } else {
    throw Exception('Failed to fetch videos. Status code: ${response.statusCode}');
  }
}

void main() async {
  final videos = await fetchYouTubeVideos('flutter tutorial');

  print(jsonEncode(videos));
}
