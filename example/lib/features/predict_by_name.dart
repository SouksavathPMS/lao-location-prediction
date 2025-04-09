import 'package:example/widgets/list_tile_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lao_location_prediction/lao_location_prediction.dart';

class PredictByName extends HookWidget {
  const PredictByName({super.key, required LocationPredictor predictor})
    : _predictor = predictor;

  final LocationPredictor _predictor;

  @override
  Widget build(BuildContext context) {
    final formKey = useRef(GlobalKey<FormState>()).value;
    final predictedLocations = useValueNotifier<List<LocationResult>>([]);
    final nameController = useTextEditingController(text: "Nongping");

    return Column(
      children: [
        Column(
          children: [
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Province, district, or village',
                    ),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
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
                final name = nameController.text;
                final predictedResult = await _predictor.searchByName(name);
                predictedLocations.value = predictedResult;
              },
              child: Text("Predict location by name"),
            ),
          ],
        ),
      ],
    );
  }
}
