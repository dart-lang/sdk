// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int add(int a, int b) => a + b;

int intArithmetic(int a, int b, List<int> data) {
  var sum = 0;
  for (var i = 0; i < data.length; ++i) {
    sum += (data[(i ~/ a * b >> 1) - 2] << a) % b;
  }
  return sum.remainder(3);
}

double doubleArithmetic(double a, int b, List<double> data) {
  double sum = 0;
  for (var i = 0; i < data.length; ++i) {
    sum += b - ((data[i] + 3) * a / b).roundToDouble();
  }
  return sum.remainder(3);
}

void main() {}
