import 'package:example/features/predict_by_name.dart';
import 'package:example/features/predict_in_bouding_box.dart';
import 'package:example/features/predict_with_radius.dart';
import 'package:example/features/predict_with_given_location.dart';
import 'package:flutter/material.dart';
import 'package:lao_location_prediction/lao_location_prediction.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocationPredictor().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lao location prediction',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Lao location prediction'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late LocationPredictor _predictor;
  @override
  void initState() {
    initializeLocationPredictor();
    super.initState();
  }

  Future<void> initializeLocationPredictor() async {
    _predictor = LocationPredictor();
    await _predictor.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            PredictWithGivenLocation(predictor: _predictor),
            SizedBox(height: 40),
            PredictWithRadius(predictor: _predictor),
            SizedBox(height: 40),
            PredictByName(predictor: _predictor),
            SizedBox(height: 40),
            PredictInBoudingBox(predictor: _predictor),
          ],
        ),
      ),
    );
  }
}
