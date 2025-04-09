import 'package:example/widgets/list_tile_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lao_location_prediction/lao_location_prediction.dart';

class PredictInBoudingBox extends HookWidget {
  const PredictInBoudingBox({super.key, required LocationPredictor predictor})
    : _predictor = predictor;

  final LocationPredictor _predictor;

  @override
  Widget build(BuildContext context) {
    final formKey = useRef(GlobalKey<FormState>()).value;
    final predictedLocations = useValueNotifier<List<LocationResult>>([]);
    final minLatController = useTextEditingController(text: "17.950000");
    final minLngController = useTextEditingController(text: "102.600000");
    final maxLatController = useTextEditingController(text: "18.050000");
    final maxLngController = useTextEditingController(text: "102.700000");

    return Column(
      children: [
        Column(
          children: [
            Form(
              key: formKey,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: minLatController,
                          decoration: InputDecoration(labelText: 'minLat'),
                          keyboardType: TextInputType.number,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.latitude(),
                          ]),
                        ),
                        TextFormField(
                          controller: minLngController,
                          decoration: InputDecoration(labelText: 'minLng'),
                          keyboardType: TextInputType.number,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.longitude(),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: maxLatController,
                          decoration: InputDecoration(labelText: 'maxLat'),
                          keyboardType: TextInputType.number,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.latitude(),
                          ]),
                        ),
                        TextFormField(
                          controller: maxLngController,
                          decoration: InputDecoration(labelText: 'maxLng'),
                          keyboardType: TextInputType.number,
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.longitude(),
                          ]),
                        ),
                      ],
                    ),
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
                final minLat = double.parse(minLatController.text);
                final minLng = double.parse(minLngController.text);
                final maxLat = double.parse(maxLatController.text);
                final maxLng = double.parse(maxLngController.text);

                final predictedResult = await _predictor
                    .getLocationsInBoundingBox(minLat, minLng, maxLat, maxLng);
                predictedLocations.value = predictedResult;
              },
              child: Text("Predict location"),
            ),
          ],
        ),
      ],
    );
  }
}
