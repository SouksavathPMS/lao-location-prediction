import 'package:example/widgets/list_tile_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lao_location_prediction/lao_location_prediction.dart';

class PredictWithGivenLocation extends HookWidget {
  const PredictWithGivenLocation({
    super.key,
    required LocationPredictor predictor,
  }) : _predictor = predictor;

  final LocationPredictor _predictor;

  @override
  Widget build(BuildContext context) {
    final formKey = useRef(GlobalKey<FormState>()).value;
    final predictedLocations = useValueNotifier<List<LocationResult>>([]);
    final latController = useTextEditingController(text: "17.410794");
    final lngController = useTextEditingController(text: "104.831894");
    final limitController = useTextEditingController(text: "5");
    return Column(
      children: [
        Column(
          children: [
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: latController,
                    decoration: InputDecoration(labelText: 'Latitude'),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.latitude(),
                    ]),
                  ),
                  TextFormField(
                    controller: lngController,
                    decoration: InputDecoration(labelText: 'Longitude'),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.longitude(),
                    ]),
                  ),
                  TextFormField(
                    controller: limitController,
                    decoration: InputDecoration(labelText: 'Limit'),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.integer(),
                    ]),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder(
              valueListenable: predictedLocations,
              builder: (context, predictedResult, child) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final location = predictedResult[index];
                    return ListTileItem(location: location);
                  },
                  separatorBuilder: (context, index) => SizedBox(height: 4),
                  itemCount: predictedResult.length,
                );
              },
            ),
            ElevatedButton(
              onPressed: () async {
                final minLat = 17.9;
                final minLng = 102.5;
                final maxLat = 18.0;
                final maxLng = 102.7;

                final boundingBoxResults = await _predictor
                    .getLocationsInBoundingBox(minLat, minLng, maxLat, maxLng);
                if (boundingBoxResults.isNotEmpty) {
                  print('Locations within the specified bounding box:');
                  for (final location in boundingBoxResults) {
                    print(
                      '${location.province}, ${location.district}, ${location.village} (${location.latitude}, ${location.longitude}) \n',
                    );
                  }
                } else {
                  print(
                    'No locations found within the specified bounding box.',
                  );
                }
                // if (formKey.currentState?.validate() != true) return;
                // final lat = double.parse(latController.text);
                // final lng = double.parse(lngController.text);
                // final limit = int.parse(limitController.text);
                // final predictedResult = await _predictor.predict(
                //   lat,
                //   lng,
                //   limit: limit,
                // );
                // predictedLocations.value = predictedResult;
              },
              child: Text("Predict location"),
            ),
          ],
        ),
      ],
    );
  }
}
