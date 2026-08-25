import 'package:flutter/material.dart';

import '../../../../core/widgets/page_header.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: PageHeader(header: 'Tasks', sub: 'Manage your tasks'),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Tasks Coming Soon',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
