import 'package:flutter/material.dart';

import '../../components/BottomNavBar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final double cardHeight = MediaQuery.of(context).size.height * 0.4;

    return Scaffold(
      // a very light green color
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCard(
                image: 'assets/report-trash.png',
                title: 'Make a Report',
                onTap: () {},
              ),
              const SizedBox(height: 20),
              _buildCard(
                image: 'assets/cleanup.png',
                title: 'Request to Cleanup',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTabTapped: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildCard({
    required String image,
    required String title,
    required VoidCallback onTap,
  }) {
    final double cardHeight = MediaQuery.of(context).size.height * 0.3;
    return SizedBox(
      height: cardHeight,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Text(title),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
