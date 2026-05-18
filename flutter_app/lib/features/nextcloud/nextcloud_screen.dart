import 'package:flutter/material.dart';

class NextcloudScreen extends StatelessWidget {
  const NextcloudScreen({super.key, this.artworkId});
  final int? artworkId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nextcloud')),
      body: const Center(child: Text('TODO')),
    );
  }
}
