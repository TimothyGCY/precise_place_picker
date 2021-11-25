import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'address_component.dart';

class LocationResult {
  String? name;
  String? locality;
  LatLng? latLng;
  String? formattedAddress;
  AddressComponent? country;
  AddressComponent? city;
  AddressComponent? administrativeAreaLevel1;
  AddressComponent? administrativeAreaLevel2;
  AddressComponent? subLocalityLevel1;
  AddressComponent? subLocalityLevel2;
  String? postalCode;
  String? placeId;
}
