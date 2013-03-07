// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library point_test;

import 'dart:html';
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';

main() {
  useHtmlConfiguration();

  test('constructor', () {
    var point = new Point();
    expect(point.x, 0);
    expect(point.y, 0);
    expect('$point', '(0, 0)');
  });

  test('constructor X', () {
    var point = new Point(10);
    expect(point.x, 10);
    expect(point.y, 0);
    expect('$point', '(10, 0)');
  });

  test('constructor X Y', () {
    var point = new Point(10, 20);
    expect(point.x, 10);
    expect(point.y, 20);
    expect('$point', '(10, 20)');
  });

  test('constructor X Y double', () {
    var point = new Point(10.5, 20.897);
    expect(point.x, 10.5);
    expect(point.y, 20.897);
    expect('$point', '(10.5, 20.897)');
  });

  test('constructor X Y NaN', () {
    var point = new Point(double.NAN, 1000);
    expect(point.x.isNaN, isTrue);
    expect(point.y, 1000);
    expect('$point', '(NaN, 1000)');
  });

  test('squaredDistanceTo', () {
    var a = new Point(7, 11);
    var b = new Point(3, -1);
    expect(a.squaredDistanceTo(b), 160);
    expect(b.squaredDistanceTo(a), 160);
  });

  test('distanceTo', () {
    var a = new Point(-2, -3);
    var b = new Point(2, 0);
    expect(a.distanceTo(b), 5);
    expect(b.distanceTo(a), 5);
  });

  test('subtract', () {
    var a = new Point(5, 10);
    var b = new Point(2, 50);
    expect(a - b, new Point(3, -40));
  });

  test('add', () {
    var a = new Point(5, 10);
    var b = new Point(2, 50);
    expect(a + b, new Point(7, 60));
  });

  test('ceil', () {
    var a = new Point(5.1, 10.8);
    expect(a.ceil(), new Point(6.0, 11.0));

    var b = new Point(5, 10);
    expect(b.ceil(), new Point(5, 10));
  });

  test('floor', () {
    var a = new Point(5.1, 10.8);
    expect(a.floor(), new Point(5.0, 10.0));

    var b = new Point(5, 10);
    expect(b.floor(), new Point(5, 10));
  });

  test('round', () {
    var a = new Point(5.1, 10.8);
    expect(a.round(), new Point(5.0, 11.0));

    var b = new Point(5, 10);
    expect(b.round(), new Point(5, 10));
  });

  test('toInt', () {
    var a = new Point(5.1, 10.8);
    var b = a.toInt();
    expect(b, new Point(5, 10));
    expect(b.x is int, isTrue);
    expect(b.y is int, isTrue);
  });
}
