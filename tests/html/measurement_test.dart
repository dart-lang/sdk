// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library MeasurementTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  test('measurement is async but before setTimout 0', () {
    final element = document.body;
    bool fnComplete = false;
    bool timeout0 = false;
    window.setTimeout(() { timeout0 = true; }, 0);
    final computedStyle = element.computedStyle;
    computedStyle.then(expectAsync1((style) {
      expect(style.getPropertyValue('left'), equals('auto'));
      expect(fnComplete, isTrue);
      expect(timeout0, isFalse);
    }));
    expect(computedStyle.isComplete, isFalse);
    fnComplete = true;
  });

  test('requestLayoutFrame', () {
    var computedStyle;
    window.requestLayoutFrame(expectAsync0(() {
      expect(computedStyle.isComplete, true);
    }));

    final element = document.body;
    computedStyle = element.computedStyle;
    expect(computedStyle.isComplete, isFalse);
  });

  // TODO(jacobr): add more tests that the results return by measurement
  // functions are correct.
}
