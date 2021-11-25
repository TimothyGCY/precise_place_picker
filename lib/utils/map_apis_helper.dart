import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapApisHelper {
  // static String apiKey;
  // static LocalizationItem localizationItem;

  static Future<LatLng?> getLatLngFromPlaceId(
      {required String apiKey, required String placeId}) async {
    if (apiKey.trim().isEmpty || placeId.trim().isEmpty) throw Error();

    try {
      var endpoint =
          "https://maps.googleapis.com/maps/api/place/details/json?key=$apiKey&placeid=$placeId";
      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode != 200) {
        throw Error();
      }

      final responseBody = jsonDecode(response.body);

      if (responseBody['result'] == null) {
        throw Error();
      }

      final location = responseBody['result']['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    } catch (e) {
      return null;
    }
  }
}
