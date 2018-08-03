// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library touch_event_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  group('functional', () {
    test('Basic TouchEvent', () {
      if (TouchEvent.supported) {
        var e = new TouchEvent('touch');
        expect(e is TouchEvent, isTrue);
      }
    });
  });
}
