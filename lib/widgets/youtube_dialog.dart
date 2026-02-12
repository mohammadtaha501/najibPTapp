import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:untitled3/utils/theme.dart';

class YouTubeGuidanceDialog extends StatefulWidget {
  final String videoUrl;
  final String title;

  const YouTubeGuidanceDialog({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<YouTubeGuidanceDialog> createState() => _YouTubeGuidanceDialogState();
}

class _YouTubeGuidanceDialogState extends State<YouTubeGuidanceDialog> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl) ?? '';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        // Ensure playback state is preserved. If it was paused, keep it paused.
        if (!_controller.value.isPlaying) {
          _controller.pause();
        }
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppTheme.primaryColor,
        topActions: <Widget>[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _controller.metadata.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        onReady: () {
          _controller.addListener(() {});
        },
      ),
      builder: (context, player) {
        return Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              player,
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

void showExerciseGuidance(BuildContext context, String title, String videoUrl) {
  showDialog(
    context: context,
    builder: (context) => YouTubeGuidanceDialog(
      title: title,
      videoUrl: videoUrl,
    ),
  );
}
