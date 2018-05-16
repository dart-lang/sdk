// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

main() {
  useHtmlConfiguration();

  test('Basic TouchEvent', () {
    if (TouchEvent.supported) {
      var e = new TouchEvent('touch');
      expect(e is TouchEvent, isTrue);
    }
  });
}
