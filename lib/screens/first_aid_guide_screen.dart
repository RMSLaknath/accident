import 'package:flutter/material.dart';

class FirstAidGuideScreen extends StatelessWidget {
  const FirstAidGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Aid Guide'),
      ),
      body: const Center(
        child: Text(
          'First Aid Guide Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
