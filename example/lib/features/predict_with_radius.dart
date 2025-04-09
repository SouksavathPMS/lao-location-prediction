import 'package:example/widgets/list_tile_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lao_location_prediction/lao_location_prediction.dart';

class PredictWithRadius extends HookWidget {
  const PredictWithRadius({super.key, required LocationPredictor predictor})
    : _predictor = predictor;

  final LocationPredictor _predictor;

  @override
  Widget build(BuildContext context) {
    final formKey = useRef(GlobalKey<FormState>()).value;
    final predictedLocations = useValueNotifier<List<LocationResult>>([]);
    final latController = useTextEditingController(text: "17.978683");
    final lngController = useTextEditingController(text: "102.640886");
    final radiusController = useTextEditingController(text: "5");
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
                    controller: radiusController,
                    decoration: InputDecoration(labelText: 'Radius (KM)'),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.numeric(),
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
                if (formKey.currentState?.validate() != true) return;
                final lat = double.parse(latController.text);
                final lng = double.parse(lngController.text);
                final radius = double.parse(radiusController.text);
                final predictedResult = await _predictor.findWithinRadius(
                  lat,
                  lng,
                  radius,
                );
                predictedLocations.value = predictedResult;
              },
              child: Text("Predict location with radius"),
            ),
          ],
        ),
      ],
    );
  }
}
