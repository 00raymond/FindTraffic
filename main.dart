import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'traffic_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

Future<List<String>> _getSuggestions(String query) async {
  if (query.isEmpty) { // Changed from 3 to 1
    return [];
  }

  final response = await http.get(Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&types=(cities)&language=en&key=$mapsKey'));

  if (response.statusCode == 200) {
    Map<String, dynamic> data = jsonDecode(response.body);
    List<String> suggestions = [];
    for (var suggestion in data['predictions']) {
      suggestions.add(suggestion['description']);
    }

    // Return only the first 5 suggestions, changed from 10 to 5
    return suggestions.take(5).toList();
  } else {
    throw Exception('Failed to load suggestions');
  }
}


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Traffic?',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _startingPointController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  PreferredSize _buildCustomAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50.0),
      child: AppBar(
        backgroundColor: Colors.purple.withOpacity(0.8),
        automaticallyImplyLeading: false,
        titleSpacing: 0.0,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TimeOfDay.now().format(context),
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    DateFormat('MM/dd/yyyy').format(DateTime.now()),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildCustomAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade100,
              Colors.white,
            ],
            stops: const [0.4, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Hero(
  tag: 'traffic',
  child: Text('Traffic?', 
    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color:Color.fromARGB(255, 82, 3, 78))),
),

                // const Text('Traffic?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color:Color.fromARGB(255, 82, 3, 78))),
                const SizedBox(height: 16),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: TypeAheadFormField<String>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _startingPointController,
                      decoration: const InputDecoration(
                        labelText: 'Starting Point',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    suggestionsCallback: _getSuggestions,
                    itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
                    onSuggestionSelected: (suggestion) => _startingPointController.text = suggestion,
                  ),
                ),
                const SizedBox(height: 16),
                const Icon(Icons.search),
                const SizedBox(height: 16),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: TypeAheadFormField<String>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _destinationController,
                      decoration: const InputDecoration(
                        labelText:'Destination',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    suggestionsCallback: _getSuggestions,
                    itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
                    onSuggestionSelected: (suggestion) => _destinationController.text = suggestion,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    print('Starting Point: ${_startingPointController.text}');
                    print('Destination: ${_destinationController.text}');
                  // Navigate to the TrafficScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrafficInfoScreen(
                      startingPoint: _startingPointController.text,
                      destination: _destinationController.text,
                      ),
                    ),
                  );
                  },
                  style: ButtonStyle(
                    minimumSize: MaterialStateProperty.all<Size>(const Size(200, 60)), // Adjust the size as needed
                  ),
                  child: const Text(
                    'Search',
                    style: TextStyle(fontSize: 20),
                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

