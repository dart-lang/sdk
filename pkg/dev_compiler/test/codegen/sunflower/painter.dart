// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library painter;

import 'dart:html';
import 'dart:math';

import 'circle.dart';

const ORANGE = "orange";
const RED = "red";
const BLUE = "blue";
const TAU = PI * 2;

Element querySelector(String selector) => document.querySelector(selector);

final canvas = querySelector("#canvas") as CanvasElement;
final context = canvas.getContext('2d') as CanvasRenderingContext2D;

abstract class CirclePainter implements Circle {
  // This demonstrates a field in a mixin.
  String color = ORANGE;

  /// Draw a small circle representing a seed centered at (x,y).
  void draw(CanvasRenderingContext2D context) {
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
