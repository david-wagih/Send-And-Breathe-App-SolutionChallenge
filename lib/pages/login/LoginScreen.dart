import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../home/HomeScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  late User? _user;
  int _credits = 0;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadUserData();
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          print('Logged in with Google: ${user.displayName}');
          setState(() {
            _user = user;
          });
          // Create a new document for the user in the "users" collection
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'credits': 0});
        }
      }
    } catch (e) {
      print('Error signing in with Google: $e');
    }
  }

  Future<void> _signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    setState(() {
      _user = null;
    });
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      if (userData.exists) {
        setState(() {
          _credits = userData.data()!['credits'];
        });
      } else {
        // Create a new document for the user in the "users" collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .set({'credits': 0});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${_user?.displayName ?? 'Guest'}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_user == null) ...[
              Text(
                'You are not signed in',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signInWithGoogle,
                child: Text('Sign in with Google'),
              ),
            ] else ...[
              CircleAvatar(
                backgroundImage: NetworkImage(_user!.photoURL ?? ''),
                radius: 50,
              ),
              SizedBox(height: 20),
              Text(
                'Credits: \$$_credits',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 20),
              Text(
                'You are signed in with Google!',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signOut,
                child: Text('Sign out'),
              ),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(),
                  ),
                );
              },
              child: Text('Go to Home Page'),
            ),
          ],
        ),
      ),
    );
  }
}
