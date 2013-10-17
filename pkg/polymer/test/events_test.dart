// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.web.events_test;

import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

@initMethod _main() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('host event', () {
    // Note: this test is currently the only event in
    // polymer/test/js/events.js at commit #7936ff8
    var testA = query('#a');
    expect(testA.xtag.clicks, isEmpty);
    testA.click();
    expect(testA.xtag.clicks, ['host click on: test-a (id a)']);
  });

  test('local event', () {
    var testB = query('#b');
    expect(testB.xtag.clicks, isEmpty);
    testB.click();
    expect(testB.xtag.clicks, []);
    var b1 = testB.shadowRoot.query('#b-1');
    b1.click();
    expect(testB.xtag.clicks, []);
    var b2 = testB.shadowRoot.query('#b-2');
    b2.click();
    expect(testB.xtag.clicks, ['local click under test-b (id b) on b-2']);
  });
}
