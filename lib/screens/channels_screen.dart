import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../services/m3u_service.dart';
import 'player_screen.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  List<Channel> _allChannels = [];
  List<Channel> _filteredChannels = [];
  List<String> _groups = [];
  String? _selectedGroup;
  bool _isLoading = true;
  String? _error;
  bool _isSearching = false;
  String? _customUrl;
  final _searchController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadChannels({String? url}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final channels = await fetchChannels(customUrl: url ?? _customUrl);
      final groups = channels
          .map((c) => c.group)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
      setState(() {
        _allChannels = channels;
        _filteredChannels = channels;
        _groups = groups;
        _isLoading = false;
        if (url != null) _customUrl = url;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters(String query) {
    setState(() {
      _filteredChannels = _allChannels.where((c) {
        final matchesSearch =
            query.isEmpty || c.name.toLowerCase().contains(query.toLowerCase());
        final matchesGroup =
            _selectedGroup == null || c.group == _selectedGroup;
        return matchesSearch && matchesGroup;
      }).toList();
    });
  }

  void _selectGroup(String? group) {
    setState(() => _selectedGroup = group);
    _applyFilters(_searchController.text);
  }

  void _showUrlDialog() {
    _urlController.text = _customUrl ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Custom M3U URL',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter any working M3U playlist URL:',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://example.com/playlist.m3u',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0D0D0D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: Search "free m3u playlist" online to find working URLs.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent),
            onPressed: () {
              final url = _urlController.text.trim();
              Navigator.pop(ctx);
              if (url.isNotEmpty) _loadChannels(url: url);
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A2E),
      elevation: 0,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search channels...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
              ),
              onChanged: _applyFilters,
            )
          : Row(
              children: [
                const Icon(Icons.tv, color: Colors.blueAccent, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'IPTV Player',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                if (!_isLoading && _error == null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '(${_filteredChannels.length})',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 13),
                    ),
                  ),
              ],
            ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _applyFilters('');
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.link, color: Colors.white),
          onPressed: _showUrlDialog,
          tooltip: 'Change source URL',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => _loadChannels(),
          tooltip: 'Reload',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 20),
            Text(
              'Loading channels...\nThis may take a moment',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, height: 1.6),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.signal_wifi_off,
                  color: Colors.red, size: 56),
              const SizedBox(height: 16),
              const Text('Failed to load channels',
                  style:
                      TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 24),
              const Text(
                'GitHub is blocked on your network.\nEnter a different M3U URL below:',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Paste your M3U URL here...',
                  hintStyle:
                      const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF1A1A2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send,
                        color: Colors.blueAccent),
                    onPressed: () {
                      final url = _urlController.text.trim();
                      if (url.isNotEmpty) _loadChannels(url: url);
                    },
                  ),
                ),
                onSubmitted: (url) {
                  if (url.trim().isNotEmpty) {
                    _loadChannels(url: url.trim());
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _loadChannels(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Default'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF2A2A3E)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_groups.isNotEmpty) _buildGroupFilter(),
        Expanded(child: _buildChannelList()),
      ],
    );
  }

  Widget _buildGroupFilter() {
    return Container(
      height: 46,
      color: const Color(0xFF12122A),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: [
          _groupChip('All', null),
          ..._groups.map((g) => _groupChip(g, g)),
        ],
      ),
    );
  }

  Widget _groupChip(String label, String? group) {
    final selected = _selectedGroup == group;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontSize: 12,
          ),
        ),
        selected: selected,
        onSelected: (_) => _selectGroup(group),
        backgroundColor: const Color(0xFF2A2A3E),
        selectedColor: Colors.blueAccent,
        checkmarkColor: Colors.black,
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildChannelList() {
    if (_filteredChannels.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: Colors.white24, size: 48),
            SizedBox(height: 12),
            Text('No channels found',
                style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _filteredChannels.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFF1E1E2E)),
      itemBuilder: (ctx, i) =>
          _buildChannelTile(_filteredChannels[i]),
    );
  }

  Widget _buildChannelTile(Channel channel) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _channelLogo(channel.logoUrl),
      title: Text(
        channel.name,
        style:
            const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: channel.group != null
          ? Text(
              channel.group!,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: const Icon(Icons.play_circle_fill,
          color: Colors.blueAccent, size: 28),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(channel: channel),
        ),
      ),
    );
  }

  Widget _channelLogo(String? logoUrl) {
    final placeholder = Container(
      width: 52,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(4),
      ),
      child:
          const Icon(Icons.tv, color: Colors.white24, size: 20),
    );

    if (logoUrl == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: logoUrl,
        width: 52,
        height: 38,
        fit: BoxFit.contain,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}
