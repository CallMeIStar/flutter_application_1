import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Distance and Temperature Checker',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(backgroundColor: Colors.orange),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Map<String, dynamic>>> futureValue;
  late Future<List<Map<String, dynamic>>> futureServoValue;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    futureValue = fetchValue();
    futureServoValue = fetchServoValue();
    timer = Timer.periodic(Duration(seconds: 3), (Timer t) {
      setState(() {
        futureValue = fetchValue(); // Update the future value every 5 seconds
        futureServoValue = fetchServoValue();
      });
    });
  }

  Future<List<Map<String, dynamic>>> fetchValue() async {
    final response = await http.get(Uri.parse('http://192.168.15.140/getValues'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<Map<String, dynamic>> dataList = jsonData.cast<Map<String, dynamic>>();
      return dataList;
    } else {
      throw Exception('Failed to load value');
    }
  }
  Future<List<Map<String, dynamic>>> fetchServoValue() async {
    final response = await http.get(Uri.parse('http://192.168.15.140/getServoValue'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<Map<String, dynamic>> dataList = jsonData.cast<Map<String, dynamic>>();
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
            const SizedBox(height: 40),
            const Row(
              children: [
                Icon(Icons.location_on_outlined),
                SizedBox(width: 10),
                Text('Distance: test'),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.thermostat_outlined),
                SizedBox(width: 10),
                Text('Temperature: test'),
              ],
            ),
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
                   // final distance = jsonData['name'];
                    final temperature = jsonData['value'];
                    final measure = jsonData['unit'];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //Text('Distance: $distance'),
                        Text('Temperature: $temperature $measure'),
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
                        //Text('Distance: $distance'),
                        Text('Value: $servovalue $measure'),
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
    );
  }
}
