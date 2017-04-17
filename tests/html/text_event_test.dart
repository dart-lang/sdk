// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library text_event_test;

import "package:expect/expect.dart";
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

import 'event_test.dart';

main() {
  useHtmlConfiguration();

  eventTest('TextEvent', () => new TextEvent('foo', view: window, data: 'data'),
      (ev) {
    expect(ev.data, 'data');
  });
}
