import 'package:flutter/material.dart';

class AddeditScreen extends StatelessWidget {
  const AddeditScreen({super.key, this.artworkId});
  final int? artworkId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Addedit')),
      body: const Center(child: Text('TODO')),
    );
  }
}
