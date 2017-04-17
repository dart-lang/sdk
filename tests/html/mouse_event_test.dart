// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mouse_event_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  test('relatedTarget', () {
    var event = new MouseEvent('mouseout');
    expect(event.relatedTarget, isNull);

    event = new MouseEvent('mouseout', relatedTarget: document.body);
    expect(event.relatedTarget, document.body);
  });
}
