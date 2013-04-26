// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library TypedArraysRangeCheckTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';
import 'dart:typed_data';

main() {
  useHtmlConfiguration();

  // Only perform tests if ArrayBuffer is supported.
  if (!Platform.supportsTypedData) {
    return;
  }

  test('outOfRangeAccess_dynamic', () {
      var a = new Uint8List(1024);

      expect(() => a[a.length], throws);
      expect(() => a[a.length + 1], throws);
      expect(() => a[a.length + 1024], throws);

      // expect(a[-1], isNull);
      // expect(a[-2], isNull);
      // expect(a[-1024], isNull);

      // It's harder to test out of range setters, but let's do some minimum.
      expect(() => a[a.length] = 0xdeadbeaf, throws);
      expect(() => a[a.length + 1] = 0xdeadbeaf, throws);
      expect(() => a[a.length + 1024] = 0xdeadbeaf, throws);

      // a[-1] = 0xdeadbeaf;
      // a[-2] = 0xdeadbeaf;
      // a[-1024] = 0xdeadbeaf;
  });

  test('outOfRange_typed', () {
      Uint8List a = new Uint8List(1024);

      expect(() => a[a.length], throws);
      expect(() => a[a.length + 1], throws);
      expect(() => a[a.length + 1024], throws);

      // expect(a[-1], isNull);
      // expect(a[-2], isNull);
      // expect(a[-1024], isNull);

      // It's harder to test out of range setters, but let's do some minimum.
      expect(() => a[a.length] = 0xdeadbeaf, throws);
      expect(() => a[a.length + 1] = 0xdeadbeaf, throws);
      expect(() => a[a.length + 1024] = 0xdeadbeaf, throws);

      // a[-1] = 0xdeadbeaf;
      // a[-2] = 0xdeadbeaf;
      // a[-1024] = 0xdeadbeaf;
  });
}
