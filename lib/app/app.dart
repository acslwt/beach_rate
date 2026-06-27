import 'package:flutter/material.dart';
import '../features/map/presentation/pages/map_page.dart';

class PlageApp extends StatelessWidget {
  const PlageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF97316),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MapPage(),
    );
  }
}
