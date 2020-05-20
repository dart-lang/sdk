// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";
import "package:expect/expect.dart";

void main() {
  test('Iterable<int>.max return the highest int', () {
    expect([2, 1, 3, 0].max, 3);
    expect([2, 1, 3, 10].max, 10);
  });
  test('Iterable<int>.max return the lowest int', () {
    expect([-2, 1, -1, 0].min, -2);
    expect([2, -1, -1, 0].min, -1);
  });
  test('Iterable<double>.min handles nan as bigger then any other double', () {
    expect([double.infinity, double.nan].min, double.infinity);
  });
  test('Iterable<Duration>.max return the longest Duration', () {
    expect([Duration(hours: 2), Duration(hours: 1)].max, Duration(hours: 2));
  });
  test('Iterable<Duration>.min return the shortest Duration', () {
    expect([Duration(hours: 2), Duration(hours: 1)].min, Duration(hours: 1));
  });
  test(
      'Iterable<Duration>.min returns the first item when '
      'multiple items have the same value', () {
    Duration firstDuration = Duration(hours: 1);
    Duration secondDuration = Duration(hours: 1);
    Duration minimumDuration = [firstDuration, secondDuration].min;

    expect(identical(firstDuration, minimumDuration), true);
    expect(identical(secondDuration, minimumDuration), false);
  });
}
