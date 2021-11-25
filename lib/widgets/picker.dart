import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:precise_place_picker/models/address_component.dart';
import 'package:precise_place_picker/models/auto_complete_item.dart';
import 'package:precise_place_picker/models/localization_item.dart';
import 'package:precise_place_picker/models/location_result.dart';
import 'package:precise_place_picker/utils/map_apis_helper.dart';
import 'package:precise_place_picker/widgets/search_input.dart';
import 'package:precise_place_picker/widgets/select_place_action.dart';
import 'package:precise_place_picker/widgets/suggestion_tile.dart';
import 'package:uuid/uuid.dart';

class PrecisePlacePicker extends StatefulWidget {
  const PrecisePlacePicker(
      {Key? key,
      required this.apiKey,
      this.defaultLocation,
      this.localizationItem})
      : super(key: key);

  /// API key generated from Google Cloud Console. Get your's from
  /// [here](https://cloud.google.com/maps-platform/)
  final String apiKey;

  /// Location to be displayed when screen is showed. If this is set or not null, the
  /// map does not pan to the user's current location.
  final LatLng? defaultLocation;
  final LocalizationItem? localizationItem;

  @override
  PrecisePlacePickerState createState() => PrecisePlacePickerState();
}

class PrecisePlacePickerState extends State<PrecisePlacePicker> {
  LocalizationItem get localizationItem =>
      widget.localizationItem ?? LocalizationItem.of(context);

  final Completer<GoogleMapController> _mapController = Completer();

  final Set<Marker> markers = {};

  LocationResult? locationResult;

  OverlayEntry? overlayEntry;

  String sessionToken = const Uuid().v4();

  GlobalKey appBarKey = GlobalKey();

  bool hasSearchTerm = false;

  String prevSearchTerm = '';

  PrecisePlacePickerState();

  void onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);
    moveToUserCurrentLocation();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    markers.add(Marker(
      markerId: const MarkerId('selected-location'),
      position: widget.defaultLocation ?? const LatLng(5.6037, 0.1870),
    ));
  }

  @override
  void dispose() {
    overlayEntry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        key: appBarKey,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left),
        ),
        title: SearchInput(searchPlace, localizationItem),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.defaultLocation ?? const LatLng(5.6037, 0.1870),
                zoom: 15,
              ),
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              onMapCreated: onMapCreated,
              onTap: (latLng) {
                clearOverlay();
                moveToLocation(latLng);
              },
              markers: markers,
            ),
          ),
          SelectPlaceAction(
            getLocationName(),
            localizationItem.tapToSelectLocation,
            () => Navigator.of(context).pop(locationResult),
          ),
        ],
      ),
    );
  }

  void searchPlace(String place) {
    // on keyboard dismissal, the search was being triggered again
    // this is to cap that.
    if (place == prevSearchTerm) {
      return;
    }

    prevSearchTerm = place;

    clearOverlay();

    setState(() {
      hasSearchTerm = place.isNotEmpty;
    });

    if (place.isEmpty) {
      return;
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    final RenderBox? appBarBox =
        appBarKey.currentContext!.findRenderObject() as RenderBox?;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: appBarBox!.size.height,
        width: size.width,
        child: Material(
          elevation: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              children: <Widget>[
                const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 3)),
                const SizedBox(width: 24),
                Expanded(
                    child: Text(localizationItem.findingPlace,
                        style: const TextStyle(fontSize: 16)))
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context)!.insert(overlayEntry!);

    autoCompleteSearch(place);
  }

  /// Hides the autocomplete overlay
  void clearOverlay() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }
  }

  /// Fetches the place autocomplete list with the query [place].
  void autoCompleteSearch(String place) async {
    try {
      place = place.replaceAll(" ", "+");

      var endpoint =
          "https://maps.googleapis.com/maps/api/place/queryautocomplete/json?" // [queryautocomplete, findplacefromtext]
          "key=${widget.apiKey}&language=${localizationItem.languageCode}&"
          "input=$place&inputtype=textquery&sessiontoken=$sessionToken";

      if (locationResult != null) {
        endpoint +=
            "&location=${locationResult!.latLng!.latitude},${locationResult!.latLng!.longitude}";
      }

      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode != 200) {
        throw Error();
      }

      final responseJson = jsonDecode(response.body);

      if (responseJson['predictions'] == null) {
        throw Error();
      }

      List<dynamic> predictions = responseJson['predictions'];

      List<SuggestionTile> suggestions = [];

      if (predictions.isEmpty) {
        AutoCompleteItem aci = AutoCompleteItem();
        aci.text = localizationItem.noResultsFound;

        suggestions.add(SuggestionTile(aci, () {}));
      } else {
        for (dynamic t in predictions) {
          final placeId = t['place_id'];
          LatLng? position = await MapApisHelper.getLatLngFromPlaceId(
              apiKey: widget.apiKey, placeId: placeId);
          final aci = AutoCompleteItem()
            ..id = placeId
            ..text = t['description']
            ..name = t['structured_formatting']['main_text']
            ..latLng = position
            ..offset = t['matched_substrings'][0]['offset']
            ..length = t['matched_substrings'][0]['length'];

          suggestions.add(SuggestionTile(aci, () {
            FocusScope.of(context).requestFocus(FocusNode());
            clearOverlay();
            moveToSelectedLocation(aci);
          }));
        }
      }

      displayAutoCompleteSuggestions(suggestions);
    } catch (e) {
      return;
    }
  }

  /// Display autocomplete suggestions with the overlay.
  void displayAutoCompleteSuggestions(List<SuggestionTile> suggestions) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;

    final RenderBox? appBarBox =
        appBarKey.currentContext!.findRenderObject() as RenderBox?;

    clearOverlay();

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        top: appBarBox!.size.height,
        child: Material(elevation: 1, child: Column(children: suggestions)),
      ),
    );

    Overlay.of(context)!.insert(overlayEntry!);
  }

  /// This method gets the human readable name of the location. Mostly appears
  /// to be the road name and the locality.
  void reverseGeocodeLatLng(LatLng latLng) async {
    try {
      final url = Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?"
          "latlng=${latLng.latitude},${latLng.longitude}&"
          "language=${localizationItem.languageCode}&"
          "key=${widget.apiKey}");

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Error();
      }

      final responseJson = jsonDecode(response.body);

      if (responseJson['results'] == null) {
        throw Error();
      }

      final result = responseJson['results'][0];

      setState(() {
        String? name,
            locality,
            postalCode,
            country,
            administrativeAreaLevel1,
            administrativeAreaLevel2,
            city,
            subLocalityLevel1,
            subLocalityLevel2;
        bool isOnStreet = false;
        if (result['address_components'] is List<dynamic> &&
            result['address_components'].length != null &&
            result['address_components'].length > 0) {
          for (var i = 0; i < result['address_components'].length; i++) {
            var tmp = result['address_components'][i];
            var types = tmp["types"] as List<dynamic>?;
            var shortName = tmp['short_name'];
            if (types == null) {
              continue;
            }
            if (i == 0) {
              // [street_number]
              name = shortName;
              isOnStreet = types.contains('street_number');
              // other index 0 types
              // [establishment, point_of_interest, subway_station, transit_station]
              // [premise]
              // [route]
            } else if (i == 1 && isOnStreet) {
              if (types.contains('route')) {
                name = (name ?? "") + ", $shortName";
              }
            } else {
              if (types.contains("sublocality_level_1")) {
                subLocalityLevel1 = shortName;
              } else if (types.contains("sublocality_level_2")) {
                subLocalityLevel2 = shortName;
              } else if (types.contains("locality")) {
                locality = shortName;
              } else if (types.contains("administrative_area_level_2")) {
                administrativeAreaLevel2 = shortName;
              } else if (types.contains("administrative_area_level_1")) {
                administrativeAreaLevel1 = shortName;
              } else if (types.contains("country")) {
                country = shortName;
              } else if (types.contains('postal_code')) {
                postalCode = shortName;
              }
            }
          }
        }
        locality = locality ?? administrativeAreaLevel1;
        city = locality;
        locationResult = LocationResult()
          ..name = name
          ..locality = locality
          ..latLng = latLng
          ..formattedAddress = result['formatted_address']
          ..placeId = result['place_id']
          ..postalCode = postalCode
          ..country = AddressComponent(name: country, shortName: country)
          ..administrativeAreaLevel1 = AddressComponent(
              name: administrativeAreaLevel1,
              shortName: administrativeAreaLevel1)
          ..administrativeAreaLevel2 = AddressComponent(
              name: administrativeAreaLevel2,
              shortName: administrativeAreaLevel2)
          ..city = AddressComponent(name: city, shortName: city)
          ..subLocalityLevel1 = AddressComponent(
              name: subLocalityLevel1, shortName: subLocalityLevel1)
          ..subLocalityLevel2 = AddressComponent(
              name: subLocalityLevel2, shortName: subLocalityLevel2);
      });
    } catch (e) {
      return;
    }
  }

  void reverseGeocodeLatLngWithItem(AutoCompleteItem item) async {
    try {
      final url = Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?"
          "latlng=${item.latLng!.latitude},${item.latLng!.longitude}&"
          "language=${localizationItem.languageCode}&"
          "key=${widget.apiKey}");

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Error();
      }

      final responseJson = jsonDecode(response.body);

      if (responseJson['results'] == null) {
        throw Error();
      }

      final result = responseJson['results'][0];

      setState(() {
        String? name,
            locality,
            postalCode,
            country,
            administrativeAreaLevel1,
            administrativeAreaLevel2,
            city,
            subLocalityLevel1,
            subLocalityLevel2;
        bool isOnStreet = false;
        if (result['address_components'] is List<dynamic> &&
            result['address_components'].length != null &&
            result['address_components'].length > 0) {
          for (var i = 0; i < result['address_components'].length; i++) {
            var tmp = result['address_components'][i];
            var types = tmp["types"] as List<dynamic>?;
            var shortName = tmp['short_name'];
            if (types == null) {
              continue;
            }
            if (i == 0) {
              // [street_number]
              name = shortName;
              isOnStreet = types.contains('street_number');
              // other index 0 types
              // [establishment, point_of_interest, subway_station, transit_station]
              // [premise]
              // [route]
            } else if (i == 1 && isOnStreet) {
              if (types.contains('route')) {
                name = (name ?? "") + ", $shortName";
              }
            } else {
              if (types.contains("sublocality_level_1")) {
                subLocalityLevel1 = shortName;
              } else if (types.contains("sublocality_level_2")) {
                subLocalityLevel2 = shortName;
              } else if (types.contains("locality")) {
                locality = shortName;
              } else if (types.contains("administrative_area_level_2")) {
                administrativeAreaLevel2 = shortName;
              } else if (types.contains("administrative_area_level_1")) {
                administrativeAreaLevel1 = shortName;
              } else if (types.contains("country")) {
                country = shortName;
              } else if (types.contains('postal_code')) {
                postalCode = shortName;
              }
            }
          }
        }
        locality = locality ?? administrativeAreaLevel1;
        city = locality;
        locationResult = LocationResult()
          ..name = item.name
          ..locality = locality
          ..latLng = item.latLng
          ..formattedAddress = result['formatted_address']
          ..placeId = item.id
          ..postalCode = postalCode
          ..country = AddressComponent(name: country, shortName: country)
          ..administrativeAreaLevel1 = AddressComponent(
              name: administrativeAreaLevel1,
              shortName: administrativeAreaLevel1)
          ..administrativeAreaLevel2 = AddressComponent(
              name: administrativeAreaLevel2,
              shortName: administrativeAreaLevel2)
          ..city = AddressComponent(name: city, shortName: city)
          ..subLocalityLevel1 = AddressComponent(
              name: subLocalityLevel1, shortName: subLocalityLevel1)
          ..subLocalityLevel2 = AddressComponent(
              name: subLocalityLevel2, shortName: subLocalityLevel2);
      });
    } catch (e) {
      return;
    }
  }

  /// Moves the marker to the indicated lat,lng
  void setMarker(LatLng latLng) {
    // markers.clear();
    setState(() {
      markers.clear();
      markers.add(Marker(
          markerId: const MarkerId("selected-location"), position: latLng));
    });
  }

  /// Utility function to get clean readable name of a location. First checks
  /// for a human-readable name from the nearby list. This helps in the cases
  /// that the user selects from the nearby list (and expects to see that as a
  /// result, instead of road name). If no name is found from the nearby list,
  /// then the road name returned is used instead.
  String getLocationName() {
    if (locationResult == null) {
      return localizationItem.unnamedLocation;
    }

    return "${locationResult!.name}, ${locationResult!.locality}";
  }

  /// Moves the camera to the provided location and updates other UI features to
  /// match the location.
  void moveToLocation(LatLng latLng) {
    _mapController.future.then((controller) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 15.0)),
      );
    });

    setMarker(latLng);

    reverseGeocodeLatLng(latLng);
  }

  void moveToUserCurrentLocation() {
    if (widget.defaultLocation != null) {
      moveToLocation(widget.defaultLocation!);
      return;
    }

    Location().getLocation().then((locationData) {
      LatLng target = LatLng(locationData.latitude!, locationData.longitude!);
      moveToLocation(target);
    }).catchError((error) {
      return;
    });
  }

  void moveToSelectedLocation(AutoCompleteItem item) {
    _mapController.future.then(
      (ctrl) => ctrl.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: item.latLng!, zoom: 15),
        ),
      ),
    );

    setMarker(item.latLng!);

    reverseGeocodeLatLngWithItem(item);
  }
}
