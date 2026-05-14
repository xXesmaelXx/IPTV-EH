import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';

const _playlistUrl =
    'https://raw.githubusercontent.com/iptv-org/iptv/master/streams/index.m3u';

List<Channel> _parseM3u(String content) {
  final channels = <Channel>[];
  final lines = content.split('\n');

  for (int i = 0; i < lines.length - 1; i++) {
    final line = lines[i].trim();
    if (!line.startsWith('#EXTINF')) continue;

    final nextLine = lines[i + 1].trim();
    if (nextLine.isEmpty || nextLine.startsWith('#')) continue;

    final nameMatch = RegExp(r',(.+)$').firstMatch(line);
    final name = nameMatch?.group(1)?.trim() ?? 'Unknown Channel';

    final logoRaw = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line)?.group(1);
    final groupRaw = RegExp(r'group-title="([^"]*)"').firstMatch(line)?.group(1);

    channels.add(Channel(
      name: name,
      streamUrl: nextLine,
      logoUrl: (logoRaw?.isNotEmpty == true) ? logoRaw : null,
      group: (groupRaw?.isNotEmpty == true) ? groupRaw : null,
    ));
  }
  return channels;
}

Future<List<Channel>> fetchChannels() async {
  final response = await http.get(Uri.parse(_playlistUrl));
  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode}: failed to load playlist');
  }
  return compute(_parseM3u, response.body);
}
