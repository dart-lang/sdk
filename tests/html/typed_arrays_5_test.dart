// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library typed_arrays_5_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  test('filter_dynamic', () {
      var a = new Float32Array(1024);
      for (int i = 0; i < a.length; i++) {
        a[i] = i;
      }

      expect(a.filter((x) => x >= 1000).length, equals(24));
  });

  test('filter_typed', () {
      Float32Array a = new Float32Array(1024);
      for (int i = 0; i < a.length; i++) {
        a[i] = i;
      }

      expect(a.filter((x) => x >= 1000).length, equals(24));
  });

  test('contains', () {
      var a = new Int16Array(1024);
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
