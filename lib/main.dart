import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Map<String, dynamic>>> futureValue;
  late Future<List<Map<String, dynamic>>> futureServoValue;
  late Timer timer;
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;

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

  @override
  void dispose() {
    timer.cancel(); // Cancel the timer when the widget is disposed
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    // final distance = jsonData['name'];
                    final temperature = jsonData['value'];
                    //  temperature.toStringAsFixed(2);
                    // final measure = jsonData['unit'];
                    final humidity = jsonData1['value'];
                    final heatIndex = jsonData2['value'];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //Text('Distance: $distance'),

                        //  SizedBox(width: 10),

                        Row(
                          children: [
                            const Icon(Icons.thermostat_outlined),
                            Text(
                              "Temperature ${temperature.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 18.0), // Adjust font size as needed
                            ),
                          ],
                        ),
                        const SizedBox(
                            height: 40), // Add a 10-pixel margin between rows
                        Row(
                          children: [
                            const Icon(Icons.water_drop_outlined),
                            Text(
                              "Humidity ${humidity.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 18.0), // Adjust font size as needed
                            ),
                          ],
                        ),
                        const SizedBox(
                            height: 40), // Add another 10-pixel margin
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department_outlined),
                            Text(
                              "Heat Index:${heatIndex.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 18.0), // Adjust font size as needed
                            ),
                          ],
                        ),

                        //
                        //
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
                    // final distance = jsonData['name'];
                    final servovalue = jsonData['value'];
                    final measure = jsonData['unit'];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            const Icon(Icons.speed_outlined),
                            //Text('Distance: $distance'),
                            Text(
                              'Value: $servovalue $measure',
                              style: const TextStyle(
                                  fontSize: 18.0), // Adjust font size as needed
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
      // Additional AppBar for the bottom button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        margin: const EdgeInsets.only(bottom: 16.0),
        child: ElevatedButton(
          onPressed: () async {
            // Navigate to a new screen for camera preview
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
      ),
    );
  }
}

class CameraPreviewScreen extends StatelessWidget {
  final CameraController controller;

  const CameraPreviewScreen({Key? key, required this.controller})
      : super(key: key);

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
            // Display camera preview when Future is complete
            return CameraPreview(controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
