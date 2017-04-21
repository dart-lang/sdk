// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library typed_arrays_5_test;

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

  test('filter_dynamic', () {
    var a = new Float32List(1024);
    for (int i = 0; i < a.length; i++) {
      a[i] = i.toDouble();
    }

    expect(a.where((x) => x >= 1000).length, equals(24));
  });

  test('filter_typed', () {
    Float32List a = new Float32List(1024);
    for (int i = 0; i < a.length; i++) {
      a[i] = i.toDouble();
    }

    expect(a.where((x) => x >= 1000).length, equals(24));
  });

  test('contains', () {
    var a = new Int16List(1024);
    for (int i = 0; i < a.length; i++) {
      a[i] = i;
    }
    expect(a.contains(0), isTrue);
    expect(a.contains(5), isTrue);
    expect(a.contains(1023), isTrue);

    expect(a.contains(-5), isFalse);
    expect(a.contains(-1), isFalse);
    expect(a.contains(1024), isFalse);
  });
}
