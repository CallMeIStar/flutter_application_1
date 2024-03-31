// ignore_for_file: avoid_print, unused_field, use_key_in_widget_constructors, prefer_const_constructors

import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Distance and Temperature Checker',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(backgroundColor: Colors.blue),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Map<String, dynamic>>> futureValue;
  late Future<List<Map<String, dynamic>>> futureServoValue;
  late Timer timer;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool switchValue = false;

  @override
  void initState() {
    super.initState();
    futureValue = fetchValue();
    futureServoValue = fetchServoValue();
    timer = Timer.periodic(const Duration(seconds: 3), (Timer t) {
      setState(() {
        futureValue = fetchValue(); // Update the future value every 5 seconds
        futureServoValue = fetchServoValue();
      });
    });
    _initializeCamera();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _controller = CameraController(firstCamera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  Future<List<Map<String, dynamic>>> fetchValue() async {
    final response =
        await http.get(Uri.parse('http://192.168.15.140/getValues'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<Map<String, dynamic>> dataList =
          jsonData.cast<Map<String, dynamic>>();
      return dataList;
    } else {
      throw Exception('Failed to load value');
    }
  }

  Future<List<Map<String, dynamic>>> fetchServoValue() async {
    final response =
        await http.get(Uri.parse('http://192.168.15.140/getServoValue'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<Map<String, dynamic>> dataList =
          jsonData.cast<Map<String, dynamic>>();
      return dataList;
    } else {
      throw Exception('Failed to load value');
    }
  }

  Future<void> setFanStatus(bool fanStatus) async {
    final url = Uri.parse('http://192.168.15.140/setStatus');
    final headers = {'Content-Type': 'application/json'};
    String state = "";
    if(fanStatus){
       state = '0';
    }else{
      state = '1';
    }
   final body = json.encode({'fanStatus': state});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      // Handle success
      print('Fan status set successfully');
    } else {
      // Handle error
      throw Exception('Failed to set fan status');
    }
  }

  @override
  void dispose() {
    timer.cancel(); // Cancel the timer when the widget is disposed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distance and Temperature Checker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 20),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: futureValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  final List<Map<String, dynamic>> dataList = snapshot.data!;
                  if (dataList.isNotEmpty) {
                    final Map<String, dynamic> jsonData = dataList[0];
                    final Map<String, dynamic> jsonData1 = dataList[1];
                    final Map<String, dynamic> jsonData2 = dataList[2];
                    final temperature = jsonData['value'];
                    final humidity = jsonData1['value'];
                    final heatIndex = jsonData2['value'];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.thermostat_outlined),
                            Text(
                              "Temperature ${temperature.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 18.0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            const Icon(Icons.water_drop_outlined),
                            Text(
                              "Humidity ${humidity.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 18.0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department_outlined),
                            Text(
                              "Heat Index:${heatIndex.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 18.0),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return const Text('No data available');
                  }
                } else {
                  return const Text('No data available');
                }
              },
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: futureServoValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  final List<Map<String, dynamic>> dataList = snapshot.data!;
                  if (dataList.isNotEmpty) {
                    final Map<String, dynamic> jsonData = dataList[0];
                    final servovalue = jsonData['value'];
                    final measure = jsonData['unit'];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            const Icon(Icons.speed_outlined),
                            Text(
                              'Value: $servovalue $measure',
                              style: const TextStyle(fontSize: 18.0),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return const Text('No data available');
                  }
                } else {
                  return const Text('No data available');
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.air_outlined),
                Text(
                  "",
                  style: TextStyle(fontSize: 18.0),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: switchValue,
                  onChanged: (value) {
                    setState(() {
                      switchValue = value;
                      // Call setFanStatus with the appropriate value
                      setFanStatus(value);
                    });
                  },
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraPreviewScreen(
                      controller: _controller,
                    ),
                  ),
                );
              },
              child: const Text('Open Camera'),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraPreviewScreen extends StatelessWidget {
  final CameraController controller;

  const CameraPreviewScreen({Key? key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Preview'),
      ),
      body: FutureBuilder<void>(
        future: controller.initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
