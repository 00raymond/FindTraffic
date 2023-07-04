import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart' as config;
import 'package:url_launcher/url_launcher.dart';

class TrafficInfoScreen extends StatefulWidget {
  final String startingPoint;
  final String destination;

  const TrafficInfoScreen({Key? key, required this.startingPoint, required this.destination}) : super(key: key);

  @override
  _TrafficInfoScreenState createState() => _TrafficInfoScreenState();
}

class _TrafficInfoScreenState extends State<TrafficInfoScreen> {
  Map<String, dynamic>? routeInfo;
  int? trafficDelay;
  int? travelTime;
  final int _timeOffset = 0;

  @override
  void initState() {
    super.initState();
    getRouteInfo();
  }

  Future<Map<String, dynamic>> getAddressCoordinates(String address) async {
  final response = await http.get(Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=AIzaSyCk0ra3iY5CWVikjlnCMdWBHiqd5QUWGOk'));

  if (response.statusCode == 200) {
    Map<String, dynamic> data = jsonDecode(response.body);
    if (data['results'].isNotEmpty) {
      return data['results'][0]['geometry']['location'];
    } else {
      throw Exception('No results found for this address');
    }
  } else {
    throw Exception('Failed to load coordinates');
  }
}

  Future<void> getRouteInfo({int hoursOffset = 0}) async {
  try {
    final startCoord = await getAddressCoordinates(widget.startingPoint);
    final endCoord = await getAddressCoordinates(widget.destination);
    final startCoordString = '${startCoord['lat']},${startCoord['lng']}';
    final endCoordString = '${endCoord['lat']},${endCoord['lng']}';
    String offsetParam = hoursOffset == 0 ? "" : "&departureTime=${DateTime.now().add(Duration(hours: hoursOffset)).toIso8601String()}";

    final response = await http.get(Uri.parse(
      'https://api.tomtom.com/routing/1/calculateRoute/$startCoordString:$endCoordString/json?key=${config.tomtomKey}&traffic=true$offsetParam'));

    if (response.statusCode == 200) {
      setState(() {
        routeInfo = jsonDecode(response.body);
        trafficDelay = routeInfo!['routes'][0]['summary']['trafficDelayInSeconds'];
        travelTime = routeInfo!['routes'][0]['summary']['travelTimeInSeconds'];
      });
    } else {
      print('Failed to load route information. Status code: ${response.statusCode}.');
      print('Response body: ${response.body}.');
      throw Exception('Failed to load route information');
    }
  } catch (e) {
    print('An error occurred: $e');
    throw Exception('Failed to load route information');
  }
}

  @override
  Widget build(BuildContext context) {
    if (routeInfo == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      // Calculate traffic status and choose the appropriate icon
      IconData trafficIcon;
      Color trafficColor;
      int trafficDelay = routeInfo!['routes'][0]['summary']['trafficDelayInSeconds'];
      if (trafficDelay < 600) { // less than 10 minutes
        trafficIcon = Icons.traffic;
        trafficColor = Colors.green;
      } else if (trafficDelay < 1800) { // less than 30 minutes
        trafficIcon = Icons.traffic;
        trafficColor = Colors.yellow;
      } else { // 30 minutes or more
        trafficIcon = Icons.traffic;
        trafficColor = Colors.red;
      }
      int travelTime = routeInfo!['routes'][0]['summary']['travelTimeInSeconds'];
      int hours = travelTime ~/ 3600; // Calculate hours
      int minutes = (travelTime % 3600) ~/ 60; // Calculate minutes

      int trafficTime = routeInfo!['routes'][0]['summary']['trafficDelayInSeconds'];
      int trafficHours = trafficTime ~/ 3600;
      int trafficMinutes = (trafficTime % 3600) ~/ 60;

      String timeText = '';
      if (hours > 0) {
        timeText += '${hours}hr ';
      }
      if (minutes > 0) {
        timeText += '${minutes}m';
      }

      String trafficText = '+';
      if (hours > 0) {
        trafficText += '${trafficHours}hr ';
      }
      if (minutes > 0) {
        trafficText += '${trafficMinutes}m';
      }
      else {
        trafficText += '0';
      }
      
      Color trafficGradient = trafficColor.withOpacity(0.01);
      Color textTrafficColor = Color.fromARGB(
        trafficColor.alpha,
        (trafficColor.red * 0.8).toInt(), // Reduce the red component by 20%
        (trafficColor.green * 0.8).toInt(), // Reduce the green component by 20%
        (trafficColor.blue * 0.8).toInt(), // Reduce the blue component by 20%
      );
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple,
          title: const Text(
            'Traffic Information',
            style: TextStyle(fontSize: 16),
           ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.pink.shade100,
                trafficGradient,
              ],
              stops: const [0.4, 1.0],
            ),
          ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                TimeOfDay.now().format(context),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, fontFamily: 'Nunito'),
              ),
              Stack(
                children: [
                  Icon(trafficIcon, size: 200, color: trafficColor),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.startingPoint} ',
                    style: const TextStyle(fontSize: 14, fontFamily: 'Nunito', fontWeight: FontWeight.w400),
                  ),
                  const Icon(Icons.arrow_forward, size: 16), // Adjust the size as needed
                  Text(
                    ' ${widget.destination}',
                    style: const TextStyle(fontSize: 14, fontFamily: 'Nunito', fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              Text(
                'Travel Time in Current Traffic: $timeText',
                style: const TextStyle(fontSize: 18, fontFamily: 'Nunito', fontWeight: FontWeight.w600),
              ),
              Text(
                'Traffic Delay: $trafficText',
                style: TextStyle(fontSize: 18, fontFamily: 'Nunito', fontWeight: FontWeight.w500, color: textTrafficColor),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    child: const Text(
                      'Open in Maps',
                      style: TextStyle(fontSize: 18, fontFamily: 'Nunito', fontWeight: FontWeight.w500),
                      ),
                    onPressed: () {
                      String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&origin=${Uri.encodeComponent(widget.startingPoint)}&destination=${Uri.encodeComponent(widget.destination)}";
                      launch(googleMapsUrl);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      );
    }
  }
}
