import 'package:flutter/material.dart';
import '../../../../core/widgets/page_header.dart';

class TrackersPage extends StatelessWidget {
  const TrackersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: PageHeader(
              header: 'Trackers',
              sub: 'Manage your trackers',
            ),
          ),
          Expanded(
            child: Center(
              child: Text('Trackers Coming Soon', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
        ],
      ),
    );
  }
}
