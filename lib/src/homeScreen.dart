import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;

import 'package:sketch_2_real/src/setDrawingArea.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SetDrawingArea?> allPoints = [];
  Widget? outputImageWidget;

  void saveSketchToImage(List<SetDrawingArea?> points) async {
    final sketchRecorder = ui.PictureRecorder();

    final canvas = Canvas(sketchRecorder,
        Rect.fromPoints(const Offset(0.0, 0.0), const Offset(200, 200)));

    Paint paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    final paintBackground = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black;

    canvas.drawRect(const Rect.fromLTWH(0, 0, 256, 256), paintBackground);

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!.points, points[i + 1]!.points, paint);
      }
    }

    final picture = sketchRecorder.endRecording();
    final imgFile = await picture.toImage(256, 256);

    final pngBytes = await imgFile.toByteData(format: ui.ImageByteFormat.png);
    final listbytes = Uint8List.view(pngBytes!.buffer);

    String base64 = base64Encode(listbytes);
    retrieveResponse(base64);
  }

  void retrieveResponse(var base64Image) async {
    var data = {"Image": base64Image};

    //:5000/predict
    var urlFlaskServer = 'http://Your IP Adress:5000/predict';
    Map<String, String> headers = {
      "Content-type": "application/json",
      "Accept": "application/json",
      "Connection": "Keep-Alive",
      "Access-Control-Allow-Origin": "*",
    };

    var body = json.encode(data);

    try {
      var response = await http.post(Uri.parse(urlFlaskServer),
          body: body, headers: headers);

      final Map<String, dynamic> responseData = json.decode(response.body);

      String outputBytes = responseData["Image"];
      print("This is Output Bytes");
      print(outputBytes);
      displayOutputImage(outputBytes.substring(2, outputBytes.length - 1));
    } catch (e) {
      print("Error Occured.");
      print(e);
      return null;
    }
  }

  void displayOutputImage(String bytes) async {
    Uint8List convertedBytes = base64Decode(bytes);

    setState(() {
      outputImageWidget = Container(
        width: 256,
        height: 256,
        child: Image.memory(
          convertedBytes,
          fit: BoxFit.cover,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Stack(
        children: [
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(9.0),
                  child: Container(
                    width: 256,
                    height: 256,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(22)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 6.0,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onPanDown: (details) {
                        setState(() {
                          allPoints.add(
                            SetDrawingArea(
                                points: details.localPosition,
                                paintArea: Paint()
                                  ..strokeCap = StrokeCap.round
                                  ..isAntiAlias = true
                                  ..color = Colors.white
                                  ..strokeWidth = 2.0),
                          );
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          allPoints.add(
                            SetDrawingArea(
                                points: details.localPosition,
                                paintArea: Paint()
                                  ..strokeCap = StrokeCap.round
                                  ..isAntiAlias = true
                                  ..color = Colors.white
                                  ..strokeWidth = 2.0),
                          );
                        });
                      },
                      onPanEnd: (details) {
                        saveSketchToImage(allPoints);

                        setState(() {
                          allPoints.add(null);
                        });
                      },
                      child: SizedBox.expand(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(22.0),
                          ),
                          child: CustomPaint(
                            painter: MyCustomPainter(allPoints: allPoints),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.55,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(22.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.cleaning_services_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            allPoints.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: SizedBox(
                    height: 256,
                    width: 256,
                    child: outputImageWidget,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<Widget>('outputImageWidget', outputImageWidget));
  }
}
