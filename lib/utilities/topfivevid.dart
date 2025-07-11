import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> fetchYouTubeVideos(String query) async {
  const String apiKey = '';
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
    for (var item in items) {
      final title = item['snippet']['title'];
      final videoId = item['id']['videoId'];
      final thumbnail = item['snippet']['thumbnails']['high']['url'];
      final link = 'https://www.youtube.com/watch?v=$videoId';

      print('Title: $title');
      print('Thumbnail: $thumbnail');
      print('Link: $link\n');
    }
  } else {
    print('Failed to fetch videos. Status code: ${response.statusCode}');
  }
}

void main(List<String> args) {
  fetchYouTubeVideos("What is internet");
}
