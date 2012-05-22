// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('MeasurementTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('measurement is async but before setTimout 0', () {
    final element = document.body;
    bool timeout0 = false;
    bool fnComplete = false;
    bool animationFrame = false;
    window.setTimeout(() { timeout0 = true; }, 0);
    final computedStyle = element.computedStyle;
    computedStyle.then(expectAsync1((style) {
      Expect.equals(style.getPropertyValue('left'), 'auto');
      Expect.isTrue(fnComplete);
      Expect.isFalse(timeout0);
      Expect.isFalse(animationFrame);
    }));
    Expect.isFalse(computedStyle.isComplete);
    fnComplete = true;
  });

  test('requestLayoutFrame', () {
    var rect;
    var computedStyle;
    window.requestLayoutFrame(expectAsync0(() {
      Expect.isTrue(rect.isComplete);
      Expect.isTrue(computedStyle.isComplete);
    }));

    final element = document.body;
    rect = element.rect;
    computedStyle = element.computedStyle;
    Expect.isFalse(rect.isComplete);
    Expect.isFalse(computedStyle.isComplete);
  });

  // TODO(jacobr): add more tests that the results return by measurement
  // functions are correct.
}
