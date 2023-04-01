import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googlemapplaceapi/constants/string_constants.dart';
import 'package:googlemapplaceapi/repository/repo.dart';
import 'package:googlemapplaceapi/utils.dart';

import 'model/place_model/place_model.dart';

Color color = const Color(0xff33ba79);

class GoogleMapScreen extends StatefulWidget {
  const GoogleMapScreen({super.key});

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen>
    with SingleTickerProviderStateMixin {
  PlaceDetailModel? _placeDetailModel;
  BitmapDescriptor? currentLocationIcon;
  BitmapDescriptor? secondLocationIcon;
  LatLng? placeLatLng;
  TextEditingController placeNameController = TextEditingController();
  Polyline? routePolyline;
  bool isRouteCreating = false;
  bool isCameraMoving = false;
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  Position? _currentPosition;
  LatLng _currentLatLng = const LatLng(27.671332124757402, 85.3125417636781);
  Marker? placeSelectedMarker;
  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _animation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _getLocation();
    super.initState();
  }

  _getLocation() async {
    var locationPermissions = await Geolocator.checkPermission();
    if (locationPermissions.name != LocationPermission.denied ||
        locationPermissions.name != LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentLatLng =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      setState(() {});
      currentLocationIcon = BitmapDescriptor.fromBytes(await getBytesFromAsset(
          path: "assets/images/currentLocation.png", width: 140));
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: _currentPosition == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  _googleMapWidget(),
                  isCameraMoving ? animatedMarkerWidget() : Container(),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 6,
                          color: Colors.white,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 50,
                                ),
                                placeNameField(),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(
                          height: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget placeNameField() {
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(12)),
        child: TextFormField(
            style: GoogleFonts.lato(),
            readOnly: true,
            controller: placeNameController,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              isDense: false,
              fillColor: Colors.transparent,
              filled: false,
              prefixIcon: Icon(CupertinoIcons.search, color: color),
              suffixIcon: InkWell(
                  onTap: () {
                    setState(() {
                      placeNameController.clear();
                    });
                  },
                  child: const Icon(Icons.clear, color: Colors.red)),
              hintText: "Place Name",
              hintStyle: GoogleFonts.lato(),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            )));
  }

  Widget _googleMapWidget() {
    return GoogleMap(
      myLocationButtonEnabled: false,
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      initialCameraPosition: CameraPosition(zoom: 16, target: _currentLatLng),
      onCameraMoveStarted: () => onCameraMoveStarted(),
      onCameraMove: (position) => onCameraMove(position),
      onCameraIdle: () => onCameraIdle(),
      onMapCreated: (controller) async {},
      polylines: routePolyline == null ? {} : {routePolyline!},
      markers: {
        placeSelectedMarker ??
            const Marker(markerId: MarkerId("0"), position: LatLng(-0, -0)),
      },
    );
  }

  void onCameraMoveStarted() {
    placeSelectedMarker = null;

    setState(() {});
    _animationController.repeat(reverse: true);
  }

  void onCameraMove(CameraPosition position) {
    placeSelectedMarker = null;
    placeLatLng = position.target;
    isCameraMoving = true;
    placeNameController.text = "Locating Place....";
    setState(() {});
  }

  void onCameraIdle() async {
    var selectedPlaceLatitude =
        double.parse("${placeLatLng?.latitude.toStringAsFixed(6)}");
    var selectedPlaceLongitude =
        double.parse("${placeLatLng?.longitude.toStringAsFixed(6)}");
    var bytesData = await getBytesFromAsset(
        path: "assets/images/placeSelectedMarker.png", width: 120);
    var point =
        '${placeLatLng?.latitude.toStringAsFixed(6)},${placeLatLng?.longitude.toStringAsFixed(6)}';
    setState(() {
      isCameraMoving = false;
      placeSelectedMarker = Marker(
          markerId: const MarkerId("0"),
          position: LatLng(selectedPlaceLatitude, selectedPlaceLongitude),
          icon: BitmapDescriptor.fromBytes(bytesData));
    });

    Map<String, dynamic> querys = {
      'latlng': point,
      'key': AppString.googleMapApiKey
    };
    _placeDetailModel = await Repo.fetchPlaceDetailFromLatLng(
        url: Uri.https("maps.googleapis.com", "maps/api/geocode/json", querys));
    placeNameController.text =
        "${_placeDetailModel?.results?.first.formatted_address}";
  }

  Widget animatedMarkerWidget() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, Widget? child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                  padding: const EdgeInsets.only(
                    bottom: 52,
                  ),
                  child: Image.asset(
                    "assets/images/placeSelectedMarker.png",
                    height: _animation.value + 55,
                  )),
              Padding(
                  padding: EdgeInsets.only(top: _animation.value * 1),
                  child: Container(
                    height: _animation.value * 1.9,
                    width: _animation.value * 4,
                    transform: Matrix4.translationValues(0, -45, 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.4),
                      boxShadow: const [
                        BoxShadow(
                          spreadRadius: 3,
                          blurRadius: 8,
                          color: Colors.black,
                        )
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
