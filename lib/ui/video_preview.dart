import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoMessagePreview {
  final ui.FrameInfo? firstFrame;
  final double width;
  final double height;

  VideoMessagePreview({this.firstFrame, this.width = 0, this.height = 0});
}

class VideoMessagePreviewJob {
  final String jobId;
  final String uri;

  VideoMessagePreviewJob({required this.jobId, required this.uri});
}

class VideoMessagePreviewResult {
  ///Fetch preview job identification
  final String jobId;

  ///Video uri
  final String uri;

  ///Preview results
  final VideoMessagePreview preview;

  VideoMessagePreviewResult(
      {required this.jobId, required this.uri, required this.preview});
}

class VideoPreviewLoader {
  ///Video controller for loading first video frame. See [ChatwootChat.build]
  VideoController controller;

  ///Queue for registering preview jobs
  final _previewJobQueue = Queue<VideoMessagePreviewJob>();

  ///Stream to send preview results
  final _previewResponseStreamController =
      StreamController<VideoMessagePreviewResult>();

  StreamSubscription? _previewResponseStreamSubscription;

  VideoPreviewLoader({required this.controller});

  void getPreview({required String jobId, required String uri}) async {
    if (_previewJobQueue.isEmpty) {
      //no video previews are being fetched
      _previewJobQueue.add(VideoMessagePreviewJob(jobId: jobId, uri: uri));
      _fromUri(jobId, uri);
    } else {
      //ongoing video preview fetch. add to queue
      _previewJobQueue.add(VideoMessagePreviewJob(jobId: jobId, uri: uri));
    }
  }

  Future<VideoMessagePreview?> _getCacheVideoPreview(
      String jobId, String uri) async {
    final fileInfo = await CachedNetworkImageProvider(uri)
        .cacheManager!
        .getFileFromCache(uri);
    if (fileInfo != null) {
      // return cached preview
      final codec =
          await ui.instantiateImageCodec(await fileInfo.file.readAsBytes());
      final frame = await codec.getNextFrame();
      final firstframe = frame;
      final width = frame.image.width.toDouble();
      final height = frame.image.height.toDouble();
      final cachedPreview = VideoMessagePreview(
          firstFrame: firstframe, width: width, height: height);
      return cachedPreview;
    }
    return null;
  }

  ///Loads first frame from video url
  Future<void> _fromUri(String jobId, String uri) async {
    //check for cached preview
    final cachedPreview = await _getCacheVideoPreview(jobId, uri);
    if (cachedPreview != null) {
      // return cached preview
      _previewResponseStreamController.add(VideoMessagePreviewResult(
          jobId: jobId, uri: uri, preview: cachedPreview));
      //check for pending jobs and execute
      if (_previewJobQueue.isNotEmpty) {
        final job = _previewJobQueue.removeFirst();
        _fromUri(job.jobId, job.uri);
      }
      return;
    }

    //fetch video preview
    ui.FrameInfo? firstframe;
    double width = 0;
    double height = 0;
    try {
      // Load the video into the player
      await controller.player.setVolume(0);
      await controller.player.open(Media(uri));
      await Future.delayed(Duration(seconds: 10));
      await controller.player.stream.position
          .firstWhere((d) => d > Duration.zero);
      Uint8List? frameBytes = await controller.player.screenshot();

      if (frameBytes != null) {
        // Convert the Uint8List to a ui.Image
        final codec = await ui.instantiateImageCodec(frameBytes);
        final frame = await codec.getNextFrame();
        firstframe = frame;
        width = frame.image.width.toDouble();
        height = frame.image.height.toDouble();
        await CachedNetworkImageProvider(uri)
            .cacheManager!
            .putFile(uri, frameBytes);
      }
    } catch (e) {
      print('Error capturing first frame: $e');
    } finally {
      // Dispose the player
      controller.player.stop();
    }

    final p = VideoMessagePreview(
        firstFrame: firstframe, width: width, height: height);

    //send preview result
    _previewResponseStreamController
        .add(VideoMessagePreviewResult(jobId: jobId, uri: uri, preview: p));

    //check for pending jobs and execute
    if (_previewJobQueue.isNotEmpty) {
      final job = _previewJobQueue.removeFirst();
      _fromUri(job.jobId, job.uri);
    }
  }

  listen(void Function(VideoMessagePreviewResult) callback) {
    _previewResponseStreamSubscription =
        _previewResponseStreamController.stream.listen(callback);
  }

  dispose() {
    _previewResponseStreamSubscription?.cancel();
  }
}
