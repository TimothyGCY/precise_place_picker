import 'package:google_maps_flutter/google_maps_flutter.dart';

class AutoCompleteItem {
  String? id;
  String? name;
  String? text;
  LatLng? latLng;
  int? offset;
  int? length;

  AutoCompleteItem({
    this.id,
    this.name,
    this.text,
    this.latLng,
    this.offset = 0,
    this.length = 0,
  });
}
