import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final String header;
  final String sub;
  final Widget? action;

  const PageHeader({
    super.key,
    required this.header,
    required this.sub,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 20.0,
        spacing: 20.0,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          ?action,
        ],
      ),
    );
  }
}
