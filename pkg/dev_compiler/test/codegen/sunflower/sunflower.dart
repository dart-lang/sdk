// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sunflower;

import 'dart:math';
import 'dom.dart';

const String ORANGE = "orange";
const int SEED_RADIUS = 2;
const int SCALE_FACTOR = 4;
const num TAU = PI * 2;
const int MAX_D = 300;
const num centerX = MAX_D / 2;
const num centerY = centerX;

Element querySelector(String selector) => document.querySelector(selector);

final InputElement slider = querySelector("#slider");
final Element notes = querySelector("#notes");
final num PHI = (sqrt(5) + 1) / 2;
int seeds = 0;
final CanvasRenderingContext2D context =
    (querySelector("#canvas") as CanvasElement).getContext('2d');

void main() {
  slider.addEventListener('change', (e) => draw());
  draw();
}

/// Draw the complete figure for the current number of seeds.
void draw() {
  seeds = int.parse(slider.value);
  context.clearRect(0, 0, MAX_D, MAX_D);
  for (var i = 0; i < seeds; i++) {
    final num theta = i * TAU / PHI;
    final num r = sqrt(i) * SCALE_FACTOR;
    final num x = centerX + r * cos(theta);
    final num y = centerY - r * sin(theta);
    new SunflowerSeed(x, y, SEED_RADIUS).draw();
  }
  notes.textContent = "$seeds seeds";
}

// This example was modified to use classes and mixins.
class SunflowerSeed extends Circle with CirclePainter {
  SunflowerSeed(num x, num y, num radius, [String color])
  : super(x, y, radius) {
    if (color != null) this.color = color;
  }
}

abstract class CirclePainter implements Circle {
  // This demonstrates a field in a mixin.
  String color = ORANGE;

  /// Draw a small circle representing a seed centered at (x,y).
  void draw() {
    context
      ..beginPath()
      ..lineWidth = 2
      ..fillStyle = color
      ..strokeStyle = color
      ..arc(x, y, radius, 0, TAU, false)
      ..fill()
      ..closePath()
      ..stroke();
  }
}

class Circle {
  final num x, y, radius;

  Circle(this.x, this.y, this.radius);
}
