# lao_location_prediction


**Location Prediction and Search for Laos**

`lao_location_prediction` is a robust Dart package designed to provide fast and accurate location-based queries specifically for locations within the Lao People's Democratic Republic. Leveraging a spatial grid, this package enables developers to easily find nearby places, search within geographical boundaries, and look up locations by name, all optimized for the context of Laos.

**Example**

![EX](https://i.postimg.cc/g0KXdk4v/example.gif)

## Key Features

* **Precise Lao Location Search:** Optimized for finding locations (provinces, districts, villages, points of interest) within Laos.
* **Nearest Location Prediction:** Quickly identify the closest locations in Laos to given coordinates.
* **Radius Search (Lao Context):** Find all locations within a specified radius (in kilometers) of a central point in Laos.
* **Name-Based Lookup:** Search for Lao locations by name, supporting Lao and potentially other relevant scripts (depending on your data).
* **Bounding Box Queries (Laos):** Retrieve locations within defined latitude and longitude boundaries within Laos.
* **Spatial Grid Efficiency:** Utilizes a spatial grid data structure for rapid query performance, especially with a large dataset of Lao locations.
* **Simple Singleton API:** Easy to integrate with a single `LocationPredictor` instance.

## Installation

To start using `lao_location_prediction` in your Dart or Flutter project, add it as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  lao_location_prediction: ^latest_version  # Replace with the actual version
```

Then, run the appropriate command in your terminal:

```bash
dart pub get
```

or for Flutter projects:

```bash
flutter pub get
```

## Getting Started

### Initializing the Predictor

The `LocationPredictor` needs to be initialized before you can use its search and prediction capabilities. This step typically involves loading the Lao location data into the spatial grid.

```dart
import 'package:lao_location_prediction/lao_location_prediction.dart';

void main() async {
  final predictor = LocationPredictor();
  try {
    await predictor.initialize();
    print('Lao Location Predictor initialized successfully!');
    // You are now ready to perform location queries.
  } catch (e) {
    print('Error initializing Lao Location Predictor: $e');
    // Handle initialization errors appropriately.
  }
}
```

### Example Usage

Here are some common use cases for the `LocationPredictor` in the context of Laos:

#### Finding the 5 Nearest Locations to Vientiane Capital

```dart
final predictor = LocationPredictor();
await predictor.initialize();

final vientianeLatitude = 17.9667;
final vientianeLongitude = 102.6000;

final nearest = await predictor.predict(vientianeLatitude, vientianeLongitude, limit: 5);
if (nearest.isNotEmpty) {
  print('5 Nearest locations to Vientiane:');
  for (final location in nearest) {
    print('${location.province}, ${location.district}, ${location.village} (${location.latitude}, ${location.longitude}) \n');
  }
} else {
  print('Could not find any nearby locations.');
}
```

#### Searching for Locations Within a 50km Radius of Luang Prabang

```dart
final predictor = LocationPredictor();
await predictor.initialize();

final luangPrabangLatitude = 19.8856;
final luangPrabangLongitude = 102.1347;
final radiusInKm = 10.0;

final withinRadius = await predictor.findWithinRadius(luangPrabangLatitude, luangPrabangLongitude, radiusInKm);
if (withinRadius.isNotEmpty) {
  print('Locations within 10km of Luang Prabang:');
  for (final location in withinRadius) {
    print('${location.province}, ${location.district}, ${location.village} (${location.latitude}, ${location.longitude}) \n');
  }
} else {
  print('No locations found within the specified radius.');
}
```

#### Searching for a Location by Name (e.g., a province or major city)

```dart
final predictor = LocationPredictor();
await predictor.initialize();

final searchTerm = "Chanthabuly";
final searchResults = await predictor.searchByName(searchTerm);
if (searchResults.isNotEmpty) {
  print('Search results for "$searchTerm":');
  for (final location in searchResults) {
    print('${location.province}, ${location.district}, ${location.village} (${location.latitude}, ${location.longitude}) \n');
  }
} else {
  print('No locations found matching "$searchTerm".');
}
```

#### Finding Locations Within a Specific Area of Laos

```dart
final predictor = LocationPredictor();
await predictor.initialize();

final minLat = 17.9;
final minLng = 102.5;
final maxLat = 18.0;
final maxLng = 102.7;

final boundingBoxResults = await predictor.getLocationsInBoundingBox(minLat, minLng, maxLat, maxLng);
if (boundingBoxResults.isNotEmpty) {
  print('Locations within the specified bounding box:');
  for (final location in boundingBoxResults) {
    print('${location.province}, ${location.district}, ${location.village} (${location.latitude}, ${location.longitude}) \n');
  }
} else {
  print('No locations found within the specified bounding box.');
}
```

## Data Source (Lao Location Data Loading)

The `lao_location_prediction` package relies on geographical data for locations within Laos. A potential source for this data is the "Laos Administrative Boundaries - Village" dataset available on Open Development Mekong:

[Laos Administrative Boundaries - Village](https://data.laos.opendevelopmentmekong.net/dataset/laos-administrative-boundaries-village)

The `lao_location_prediction` package initializes its spatial grid and location data during the `LocationPredictor.initialize()` process. This involves loading data from two primary asset files bundled with the package:

1.  **`grid_metadata.json`:** This file contains essential metadata for setting up the spatial grid, such as the minimum and maximum latitude and longitude defining the geographical boundaries of your Lao location data, as well as the grid size.

    **Example `grid_metadata.json` structure:**

    ```json
    {
        "min_lat": 13.93824063,
        "min_lng": 100.0890119,
        "max_lat": 22.44057616,
        "max_lng": 107.61953604,
    }
    ```

2.  **`default_data.json`:** This file contains the actual Lao location data. It is expected to be a JSON array of feature objects, following a structure that includes `geometry` (with `coordinates` as `[longitude, latitude]`) and `properties` containing location details. Each object should be parsable by the `LocationResult.fromJson()` method.

    **Example `default_data.json` structure (illustrative):**

    ```json
    [
      {
        "id": "unique_id_1",
        "geometry": {
          "type": "Point",
          "coordinates": [102.6000, 17.9667] // [longitude, latitude]
        },
        "properties": {
          "urcne": "Vientiane Prefecture", // Province/Region Code Name English
          "uscne": "Vientiane Capital",   // Sub-Region/City Code Name English
          "uucne": "Chanthabouly",       // Specific Location/Village Code Name English
          // ... other relevant properties
        }
      },
      {
        "id": "unique_id_2",
        "geometry": {
          "type": "Point",
          "coordinates": [102.1347, 19.8856] // [longitude, latitude]
        },
        "properties": {
          "urcne": "Luang Prabang Province",
          "uscne": "Luang Prabang City",
          "uucne": "City Center",
          // ... other properties
        }
      },
      // ... more Lao locations
    ]
    ```

    The `_loadInitialData()` method within the `SpatialGrid` class reads this JSON file. For each feature, it extracts the `latitude` and `longitude` from the `geometry.coordinates` array (remembering that the order is **[longitude, latitude]**), and the province, district (USCNE), and village (UUCNE) from the `properties`. The `id` from the top-level JSON object is also used. These values are then used to create `LocationResult` objects, which are added to the spatial grid for efficient querying.

## Contributing

> Me welcome contributions that enhance the accuracy and coverage of Lao location data, improve the efficiency of the spatial grid for Lao geographical contexts, or add new features relevant to location services in Laos. Please feel free to open issues or submit pull requests on [SouksavathPMS](https://github.com/SouksavathPMS/lao-location-prediction).


## Buy Me a Coffee ☕

If you find this `lao_location_prediction` package helpful and would like to support its development and maintenance, you can buy me a coffee! Your support is greatly appreciated.


**Scan the QR Code:**
![QR](https://i.postimg.cc/1t9FNN4C/qr.jpg)


Thank you for your support! 🙏

