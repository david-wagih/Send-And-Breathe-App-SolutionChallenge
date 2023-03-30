import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../login/LoginScreen.dart';
import '../processImage.dart';

class SubmitRequest extends StatefulWidget {
  final String wasteReportId;

  const SubmitRequest({required this.wasteReportId, Key? key})
      : super(key: key);

  @override
  State<SubmitRequest> createState() => _SubmitRequestState();
}

class _SubmitRequestState extends State<SubmitRequest> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
  }

  Future<void> getImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: source);
    setState(() {
      _imageFile = image;
    });
  }

  void _reportWaste() async {
    //print(widget.wasteReportId);
    final result = await processImage(File(_imageFile!.path));
    if (result['result'] == 'clean') {
      final user = FirebaseAuth.instance.currentUser;
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user!.uid);

      await FirebaseFirestore.instance
          .collection('waste_reports')
          .doc(widget.wasteReportId)
          .delete()
          .then((value) => print('Waste report deleted'))
          .catchError(
              (error) => print('Failed to delete waste report: $error'));

      await userDocRef.update({'credits': FieldValue.increment(50)});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Congratulations, You\'ve done it!'),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit a Cleanup Request'),
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
                      children: const [
                        Icon(Icons.camera_alt),
                        SizedBox(width: 5),
                        Text('Take Photo'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _reportWaste();
        },
        tooltip: 'Submit',
        child: const Icon(Icons.send),
      ),
    );
  }
}
