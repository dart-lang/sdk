// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sunflower;

import 'dart:html';
import 'dart:math';

import 'circle.dart';
import 'painter.dart';

const SEED_RADIUS = 2;
const SCALE_FACTOR = 4;
const MAX_D = 300;
const centerX = MAX_D / 2;
const centerY = centerX;

Element querySelector(String selector) => document.querySelector(selector);
final canvas = querySelector("#canvas") as CanvasElement;
final context = canvas.getContext('2d') as CanvasRenderingContext2D;
final slider = querySelector("#slider") as InputElement;
final notes = querySelector("#notes");

final PHI = (sqrt(5) + 1) / 2;
int seeds = 0;

void main() {
  slider.addEventListener('change', (e) => draw());
  draw();
}

/// Draw the complete figure for the current number of seeds.
void draw() {
  seeds = int.parse(slider.value);
  context.clearRect(0, 0, MAX_D, MAX_D);
  for (var i = 0; i < seeds; i++) {
    final theta = i * TAU / PHI;
    final r = sqrt(i) * SCALE_FACTOR;
    final x = centerX + r * cos(theta);
    final y = centerY - r * sin(theta);
    new SunflowerSeed(x, y, SEED_RADIUS).draw(context);
  }
  notes.text = "$seeds seeds";
}

// This example was modified to use classes and mixins.
class SunflowerSeed extends Circle with CirclePainter {
  SunflowerSeed(num x, num y, num radius, [String color])
  : super(x, y, radius) {
    if (color != null) this.color = color;
  }
}
