import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/channel.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _controller?.dispose();
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.channel.streamUrl),
      );
      await _controller!.initialize();
      await _controller!.play();
      _controller!.addListener(() => setState(() {}));
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showControls = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.channel.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.channel.group != null)
              Text(widget.channel.group!,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: GestureDetector(
                onTap: _toggleControls,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(color: Colors.black),
                    if (_controller != null &&
                        !_isLoading &&
                        _error == null)
                      VideoPlayer(_controller!),
                    if (_isLoading)
                      const CircularProgressIndicator(
                          color: Colors.blueAccent),
                    if (_error != null)
                      _buildErrorOverlay(),
                    if (!_isLoading &&
                        _error == null &&
                        _showControls)
                      _buildControlsOverlay(),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildChannelInfo()),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final isPlaying = _controller?.value.isPlaying ?? false;
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.black38,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10,
                    color: Colors.white, size: 36),
                onPressed: () {
                  final pos = _controller!.value.position;
                  _controller!.seekTo(
                      pos - const Duration(seconds: 10));
                },
              ),
              const SizedBox(width: 20),
              IconButton(
                iconSize: 56,
                icon: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.white,
                ),
                onPressed: () {
                  isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                },
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.forward_10,
                    color: Colors.white, size: 36),
                onPressed: () {
                  final pos = _controller!.value.position;
                  _controller!.seekTo(
                      pos + const Duration(seconds: 10));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_outlined,
                color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('Stream unavailable',
                style:
                    TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initPlayer,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.channel.name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          if (widget.channel.group != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.blueAccent.withOpacity(0.5)),
              ),
              child: Text(widget.channel.group!,
                  style: const TextStyle(
                      color: Colors.blueAccent, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2A2A3E)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.live_tv, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              const Text('LIVE',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const Spacer(),
              TextButton.icon(
                onPressed: _initPlayer,
                icon: const Icon(Icons.refresh,
                    color: Colors.white54, size: 16),
                label: const Text('Reload stream',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
