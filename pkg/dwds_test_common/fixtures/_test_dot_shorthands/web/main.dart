// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 3.10

class C {
  int value;
  C(this.value); // lineA

  static C two = C(2); // lineB
  static C get three => C(3); // lineC
  static C four() => C(4); // lineD
}

void testDotShorthands() {
  C c = C(1);
  print('breakpoint'); // Breakpoint: testDotShorthands
  // ignore: experiment_not_enabled
  c = .two; // lineE
  // ignore: experiment_not_enabled
  c = .three; // lineF
  // ignore: experiment_not_enabled
  c = .four(); // lineG
  print(c.value); // lineH
}

void main() {}
