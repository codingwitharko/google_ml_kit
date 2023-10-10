import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as imglib;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:processing_camera_image/processing_camera_image.dart';

import 'detector_view.dart';
import 'painters/face_detector_painter.dart';

class FaceDetectorView extends StatefulWidget {
  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.front;

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DetectorView(
        title: 'Face Detector',
        customPaint: _customPaint,
        text: _text,
        onImage: _processImage,
        initialCameraLensDirection: _cameraLensDirection,
        onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final faces = await _faceDetector.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(
        faces,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);
      print('++++++++++++++++++++++');
      print('++++++++++++++++++++++');
      print('++++++++++++++++++++++');
      print('++++++++++++++++++++++');
      print('++++++++++++++++++++++');
      print('headEulerAngleX :${faces.first.headEulerAngleX}');
      print('headEulerAngleY :${faces.first.headEulerAngleY}');
      print('headEulerAngleZ :${faces.first.headEulerAngleZ}');
      print('++++++++++++++++++++++');
      print('++++++++++++++++++++++');
      print('++++++++++++++++++++++');
      print('++++++++++++++++++++++');
      print('++++++++++++++++++++++');
      if ((faces.first.headEulerAngleX! < 0.8 ||
              faces.first.headEulerAngleX! > -0.8) &&
          (faces.first.headEulerAngleY! < 0.8 ||
              faces.first.headEulerAngleY! > -0.8) &&
          (faces.first.headEulerAngleZ! < 0.8 ||
              faces.first.headEulerAngleZ! > -0.8)) {
        print('########################');
        print('########################');
        print('format:${inputImage.metadata!.format}');
        print('size:${inputImage.metadata!.size}');
        print('########################');
        print('########################');
        saveImage(inputImage);
      }
      //inputImage.bytes
    } else {
      String text = 'Faces found: ${faces.length}\n\n';
      for (final face in faces) {
        text += 'face: ${face.boundingBox}\n\n';
      }
      _text = text;
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  void saveImage(InputImage img) async {
    if (await Permission.manageExternalStorage.status !=
        PermissionStatus.granted) {
      await Permission.manageExternalStorage.request();
    }
    if (await Permission.storage.status != PermissionStatus.granted) {
      await Permission.storage.request();
    }

    final directory = (await getTemporaryDirectory()).path;
    File imgFile = File('$directory/${DateTime.now()}.png');
    await imgFile.create(recursive: true);
    imglib.Image? currentImage = await processImage(savedImage: img);
    imgFile.writeAsBytes(Uint8List.fromList(imglib.encodePng(currentImage!)));
    var result = await ImageGallerySaver.saveImage(Uint8List.fromList(imglib.encodePng(currentImage)));
    print('########################');
    print('########################');
    print('image is saved');
    print('$result');
    print('########################');
    print('########################');
  }
}

Future<imglib.Image?> processImage({required InputImage savedImage}) async {
  final ProcessingCameraImage _processingCameraImage = ProcessingCameraImage();
  return _processingCameraImage.processCameraImageToRGB(
    width: savedImage.metadata!.size.width.toInt(),
    height: savedImage.metadata!.size.height.toInt(),
    plane0: savedImage.bytes,
    rotationAngle: -90,
    backGroundColor: Colors.red.value,
    isFlipVectical: true,
  );
}
