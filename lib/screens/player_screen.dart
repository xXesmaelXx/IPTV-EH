import 'package:chewie/chewie.dart';
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
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

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
      _chewieController?.dispose();
      _videoController?.dispose();

      final uri = Uri.parse(widget.channel.streamUrl);
      _videoController = VideoPlayerController.networkUrl(uri);
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        isLive: true,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blueAccent,
          handleColor: Colors.blueAccent,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        errorBuilder: (ctx, msg) => _buildError(msg),
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_outlined,
              color: Colors.red, size: 48),
          const SizedBox(height: 12),
          const Text('Stream unavailable',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _initPlayer,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
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
              Text(
                widget.channel.group!,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Colors.blueAccent))
                  : _error != null
                      ? _buildError(_error!)
                      : Chewie(controller: _chewieController!),
            ),
            Expanded(
              child: Padding(
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
                              color:
                                  Colors.blueAccent.withOpacity(0.5)),
                        ),
                        child: Text(
                          widget.channel.group!,
                          style: const TextStyle(
                              color: Colors.blueAccent, fontSize: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF2A2A3E)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.live_tv,
                            color: Colors.red, size: 16),
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
                                  color: Colors.white54,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
