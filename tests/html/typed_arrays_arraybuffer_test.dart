// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library typed_arrays_arraybuffer_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';
import 'dart:typed_data';

main() {
  useHtmlConfiguration();

  // Only perform tests if ArrayBuffer is supported.
  if (!Platform.supportsTypedData) {
    return;
  }

  test('constructor', () {
    var a = new Int8List(100);
    expect(a.lengthInBytes, 100);
  });

  test('sublist1', () {
    var a = new Int8List(100);
    var s = a.sublist(10, 40);
    expect(s.length, 30);
  });

  test('sublist2', () {
    var a = new Int8List(100);
    expect(() => a.sublist(10, 400), throwsRangeError);
  });

  test('sublist3', () {
    var a = new Int8List(100);
    expect(() => a.sublist(50, 10), throwsRangeError);
  });

  test('sublist4', () {
    var a = new Int8List(100);
    expect(() => a.sublist(-90, -30), throwsRangeError);
  });
}
