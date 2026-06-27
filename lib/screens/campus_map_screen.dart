import 'package:flutter/material.dart';

class CampusMapScreen extends StatelessWidget {
  const CampusMapScreen({super.key});

  static const locations = [
    ('Library', Alignment(-0.55, -0.55), Color(0xFF42A5F5)),
    ('Cafeteria', Alignment(0.58, -0.38), Color(0xFFFF8A65)),
    ('Lecture Hall A', Alignment(-0.1, 0.05), Color(0xFF6C63FF)),
    ('Computer Lab', Alignment(0.48, 0.35), Color(0xFF4DB6AC)),
    ('Security Office', Alignment(-0.58, 0.52), Color(0xFF22223B)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Map')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12, width: 3),
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                  for (final location in locations)
                    Align(
                      alignment: location.$2,
                      child: Tooltip(
                        message: location.$1,
                        child: CircleAvatar(
                          backgroundColor: location.$3,
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final location in locations)
            ListTile(
              leading: CircleAvatar(backgroundColor: location.$3),
              title: Text(location.$1),
              subtitle: const Text('Common lost-and-found location'),
            ),
        ],
      ),
    );
  }
}
