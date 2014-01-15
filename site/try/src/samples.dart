// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.samples;

const String EXAMPLE_HELLO = r'''
// Go ahead and modify this example.

var greeting = "Hello, World!";

// Prints a greeting.
void main() {
  // The [print] function displays a message in the "Console" box.
  // Try modifying the greeting above and watch the "Console" box change.
  print(greeting);
}
''';

const String EXAMPLE_HELLO_HTML = r'''
// Go ahead and modify this example.

import "dart:html";

var greeting = "Hello, World!";

// Displays a greeting.
void main() {
  // This example uses HTML to display the greeting and it will appear
  // in a nested HTML frame (an iframe).
  document.body.append(new HeadingElement.h1()..appendText(greeting));
}
''';

const String EXAMPLE_FIBONACCI = r'''
// Go ahead and modify this example.

// Computes the nth Fibonacci number.
int fibonacci(int n) {
  if (n < 2) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

// Prints a Fibonacci number.
void main() {
  int i = 20;
  String message = "fibonacci($i) = ${fibonacci(i)}";
  // Print the result in the "Console" box.
  print(message);
}
''';

const String EXAMPLE_FIBONACCI_HTML = r'''
// Go ahead and modify this example.

import "dart:html";

// Computes the nth Fibonacci number.
int fibonacci(int n) {
  if (n < 2) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

// Displays a Fibonacci number.
void main() {
  int i = 20;
  String message = "fibonacci($i) = ${fibonacci(i)}";

  // This example uses HTML to display the result and it will appear
  // in a nested HTML frame (an iframe).
  document.body.append(new HeadingElement.h1()..appendText(message));
}
''';

// Test that math.png is displayed correctly (centered without 3d border).
// Test that slider works and changes size of sunflower.
const String EXAMPLE_SUNFLOWER = '''
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sunflower;

import "dart:html";
import "dart:math";

const String ORANGE = "orange";
const int SEED_RADIUS = 2;
const int SCALE_FACTOR = 4;
const num TAU = PI * 2;
const int MAX_D = 300;
const num centerX = MAX_D / 2;
const num centerY = centerX;

final InputElement slider = query("#slider");
final Element notes = query("#notes");
final num PHI = (sqrt(5) + 1) / 2;
int seeds = 0;
final CanvasRenderingContext2D context =
  (query("#canvas") as CanvasElement).context2D;

void main() {
  document.head.append(new StyleElement()..appendText(STYLE));
  document.body.innerHtml = BODY;
  ImageElement img = document.querySelector("#math_png");
  img.src = MATH_PNG;
  slider.onChange.listen((e) => draw());
  draw();
}

/// Draw the complete figure for the current number of seeds.
void draw() {
  seeds = int.parse(slider.value);
  context.clearRect(0, 0, MAX_D, MAX_D);
  for (var i = 0; i < seeds; i++) {
    final num theta = i * TAU / PHI;
    final num r = sqrt(i) * SCALE_FACTOR;
    drawSeed(centerX + r * cos(theta), centerY - r * sin(theta));
  }
  notes.text = "\${seeds} seeds";
}

/// Draw a small circle representing a seed centered at (x,y).
void drawSeed(num x, num y) {
  context..beginPath()
         ..lineWidth = 2
         ..fillStyle = ORANGE
         ..strokeStyle = ORANGE
         ..arc(x, y, SEED_RADIUS, 0, TAU, false)
         ..fill()
         ..closePath()
         ..stroke();
}

const String MATH_PNG =
    "https://dart.googlecode.com/svn/trunk/dart/samples/sunflower/web/math.png";
const String BODY = """
    <h1>drfibonacci\'s Sunflower Spectacular</h1>

    <p>A canvas 2D demo.</p>

    <div id="container">
      <canvas id="canvas" width="300" height="300" class="center"></canvas>
      <form class="center">
        <input id="slider" type="range" max="1000" value="500"/>
      </form>
      <br/>
      <img id="math_png" width="350px" height="42px" class="center">
    </div>

    <footer>
      <p id="summary"> </p>
      <p id="notes"> </p>
    </footer>
""";

const String STYLE = r"""
body {
  background-color: #F8F8F8;
  font-family: \'Open Sans\', sans-serif;
  font-size: 14px;
  font-weight: normal;
  line-height: 1.2em;
  margin: 15px;
}

p {
  color: #333;
}

#container {
  width: 100%;
  height: 400px;
  position: relative;
  border: 1px solid #ccc;
  background-color: #fff;
}

#summary {
  float: left;
}

#notes {
  float: right;
  width: 120px;
  text-align: right;
}

.error {
  font-style: italic;
  color: red;
}

img {
  border: 1px solid #ccc;
  margin: auto;
}

.center {
  display: block;
  margin: 0px auto;
  text-align: center;
}
""";
''';
