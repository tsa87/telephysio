import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VideoPlayerScreen();
  }
}

class VideoPlayerScreen extends StatefulWidget {
  VideoPlayerScreen({Key key}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    // Create and store the VideoPlayerController. The VideoPlayerController
    // offers several different constructors to play videos from assets, files,
    // or the internet.
    _controller = VideoPlayerController.network(
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    );

    // Initialize the controller and store the Future for later use.
    _initializeVideoPlayerFuture = _controller.initialize();

    // Use the controller to loop the video.
    _controller.setLooping(true);

    _controller.play();

    super.initState();
  }

  @override
  void dispose() {
    // Ensure disposing of the VideoPlayerController to free up resources.
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If the VideoPlayerController has finished initialization, use
          // the data it provides to limit the aspect ratio of the video.
          return SizedBox(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              // Use the VideoPlayer widget to display the video.
              child: VideoPlayer(_controller),
            ),
            height: 120,
            width: 80,
          );
        } else {
          // If the VideoPlayerController is still initializing, show a
          // loading spinner.
          return SizedBox(child: CircularProgressIndicator());
        }
      },
    );
  }
}

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(CameraApp());
}

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  VideoPlayerController _videoController;
  Future<void> _initializeVideoPlayerFuture;

  CameraController controller;
  int currentCameraIndex = 0;
  int cameraCount = cameras.length;

  @override
  void initState() {
    super.initState();
    controller =
        CameraController(cameras[currentCameraIndex], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
      setState(() {});
    }

    controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  void logError(String code, String message) =>
      print('Error: $code\nError Message: $message');

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  controller == null
                      ? CircularProgressIndicator()
                      : AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: CameraPreview(controller),
                        ),
                  Positioned(
                    top: 20.0,
                    left: 20.0,
                    child: IconButton(
                        icon: Icon(
                          Icons.swap_horizontal_circle,
                          size: 36.0,
                        ),
                        onPressed: () {
                          currentCameraIndex =
                              (currentCameraIndex + 1) % cameraCount;
                          onNewCameraSelected(cameras[currentCameraIndex]);
                        }),
                  ),
                  Positioned(top: 20.0, right: 20.0, child: VideoPlayerApp())
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
