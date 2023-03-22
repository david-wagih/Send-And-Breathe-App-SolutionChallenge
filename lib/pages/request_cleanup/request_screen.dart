import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({Key? key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  Set<Marker> _markers = {};
  late GoogleMapController _mapController;
  LocationData? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final location = Location();
    final permissionStatus = await location.requestPermission();
    if (permissionStatus == PermissionStatus.granted) {
      final currentLocation = await location.getLocation();
      setState(() {
        _currentLocation = currentLocation;
        _markers.add(
          Marker(
            markerId: MarkerId('marker1'),
            position: LatLng(
                _currentLocation!.latitude!, _currentLocation!.longitude!),
            infoWindow: InfoWindow(title: 'Your Location'),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentLocation != null
          ? GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    _currentLocation!.latitude!, _currentLocation!.longitude!),
                zoom: 14,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            )
          : Center(child: CircularProgressIndicator()),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.green,
        ),
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
