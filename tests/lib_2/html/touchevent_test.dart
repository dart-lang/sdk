// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  group('supported', () {
    test('supported', () {
      expect(TouchEvent.supported, isTrue);
    });
  });

  group('functional', () {
    test('unsupported throws', () {
      var expectation = TouchEvent.supported ? returnsNormally : throws;

      expect(() {
        var e = new TouchEvent(null, null, null, 'touch');
        expect(e is TouchEvent, isTrue);
      }, expectation);
    });
  });
}
