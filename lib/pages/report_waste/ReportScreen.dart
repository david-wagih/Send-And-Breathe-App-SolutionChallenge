import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  XFile? _imageFile;
  TextEditingController _descriptionController = TextEditingController();

  Future<void> getImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: source);
    setState(() {
      _imageFile = image;
    });
  }

  Future<void> _reportWaste() async {
    // Upload the image to Firebase Storage
    final Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final UploadTask uploadTask = storageRef.putFile(File(_imageFile!.path));

    // Create a stream to track the upload progress
    final Stream<TaskSnapshot> stream = uploadTask.snapshotEvents;

    // Store the details in Firebase Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Request location permission on the same thread
      final location = Location();
      final permissionStatus = await location.requestPermission();
      if (permissionStatus == PermissionStatus.granted) {
        final currentLocation = await location.getLocation();
        final locationData =
            GeoPoint(currentLocation.latitude!, currentLocation.longitude!);

        // Show a loading dialog while the image is being uploaded
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            int percentage = 0;

            // Use a StreamBuilder to update the UI based on the upload progress
            return StreamBuilder<TaskSnapshot>(
              stream: stream,
              builder:
                  (BuildContext context, AsyncSnapshot<TaskSnapshot> snapshot) {
                if (snapshot.hasData) {
                  final progress = (snapshot.data!.bytesTransferred /
                          snapshot.data!.totalBytes) *
                      100;
                  percentage = progress.toInt();

                  // Update the percentage indicator
                  return AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(value: progress / 100),
                        SizedBox(width: 20),
                        Text('$percentage%'),
                      ],
                    ),
                  );
                } else {
                  // Show a generic loading indicator while waiting for the upload to start
                  return AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Text('Uploading...'),
                      ],
                    ),
                  );
                }
              },
            );
          },
        );

        // Wait for the upload to complete and dismiss the loading dialog
        await uploadTask.whenComplete(() => Navigator.pop(context));

        await FirebaseFirestore.instance.collection('waste_reports').add({
          'user_id': user.uid,
          'image_url': await storageRef.getDownloadURL(),
          'description': _descriptionController.text,
          'location': locationData,
          'timestamp': DateTime.now(),
        });

        // Show a success message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report submitted successfully!'),
          ),
        );
        Navigator.pushNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Waste'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _imageFile == null
                  ? Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: Colors.grey,
                        ),
                      ),
                      child: Icon(Icons.image),
                    )
                  : Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2,
                          color: Colors.grey,
                        ),
                        image: DecorationImage(
                          image: FileImage(File(_imageFile!.path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      getImage(ImageSource.gallery);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.image),
                        SizedBox(width: 5),
                        Text('Select Image'),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      getImage(ImageSource.camera);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt),
                        SizedBox(width: 5),
                        Text('Take Photo'),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              SizedBox(
                width: 250,
                height: 200,
                child: TextField(
                  controller: _descriptionController,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter description',
                    hintStyle: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey[400],
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.grey[400]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _reportWaste();
        },
        tooltip: 'Report Waste',
        child: const Icon(Icons.send),
      ),
    );
  }
}
