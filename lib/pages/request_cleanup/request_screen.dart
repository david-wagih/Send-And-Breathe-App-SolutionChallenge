import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendandbreathe/pages/request_cleanup/submit_request.dart';

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
          ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('waste_reports')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final wasteReports = snapshot.data!.docs;

                _markers.clear();

                for (final report in wasteReports) {
                  final reportData = report.data() as Map<String, dynamic>;
                  final locationData = reportData['location'] as GeoPoint?;
                  final latitude = locationData?.latitude;
                  final longitude = locationData?.longitude;
                  final description = reportData['description'] as String?;
                  final imageUrl = reportData['image_url'] as String?;

                  if (latitude != null && longitude != null) {
                    _markers.add(
                      Marker(
                        markerId: MarkerId(report.id),
                        position: LatLng(latitude, longitude),
                        infoWindow: InfoWindow(
                          title: reportData['type'],
                          snippet: description,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueViolet,
                        ),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Container(
                                height: 200,
                                child: Column(
                                  children: [
                                    if (imageUrl != null)
                                      Image.network(
                                        imageUrl,
                                        height: 100,
                                      ),
                                    if (description != null)
                                      Text(
                                        description,
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SubmitRequest(
                                                wasteReportId: report.id),
                                          ),
                                        );
                                      },
                                      child: Text('Request Cleanup'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  }
                }

                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentLocation!.latitude!,
                        _currentLocation!.longitude!),
                    zoom: 14,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                );
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
