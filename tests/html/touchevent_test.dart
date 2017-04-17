// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library touch_event_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(TouchEvent.supported, true);
    });
  });

  group('functional', () {
    test('unsupported throws', () {
      var expectation = TouchEvent.supported ? returnsNormally : throws;

      expect(() {
        var e = new TouchEvent(null, null, null, 'touch');
        expect(e is TouchEvent, true);
      }, expectation);
    });
  });
}
