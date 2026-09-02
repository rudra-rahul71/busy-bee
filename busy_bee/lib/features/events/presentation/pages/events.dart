import 'package:flutter/material.dart';

import '../../../../core/widgets/page_header.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: PageHeader(header: 'Events', sub: 'Manage your events'),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Events Coming Soon',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
