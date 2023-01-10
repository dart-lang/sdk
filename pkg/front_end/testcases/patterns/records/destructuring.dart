// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(double lat, double long) getLocation(String name) {
  if (name == 'Aarhus') {
    return (56.1629, 10.2039);
  } else {
    return (0, 0);
  }
}

void main(List<String> arguments) {
  final (lat, long) = getLocation('Aarhus');
  print('Current location: $lat, $long');
  expect(56.1629, lat);
  expect(10.2039, long);
}

expect(expected, actual) {
  if (expected != actual) throw "Expected $expected, actual $actual";
}