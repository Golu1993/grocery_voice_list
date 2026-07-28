import 'package:flutter/material.dart';

class OffsetFabLocation extends FloatingActionButtonLocation {
  const OffsetFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final defaultOffset =
    FloatingActionButtonLocation.endFloat.getOffset(geometry);

    return Offset(
      (defaultOffset.dx) - 20, // Move 20px left
      defaultOffset.dy - 60, // Move 30px up
    );
  }
}