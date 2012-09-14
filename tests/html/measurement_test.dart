// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('MeasurementTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
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
      expect(style.getPropertyValue('left'), equals('auto'));
      expect(fnComplete);
      expect(timeout0, isFalse);
      expect(animationFrame, isFalse);
    }));
    Expect.isFalse(computedStyle.isComplete);
    fnComplete = true;
  });

  test('requestLayoutFrame', () {
    var rect;
    var computedStyle;
    window.requestLayoutFrame(expectAsync0(() {
      expect(rect.isComplete);
      expect(computedStyle.isComplete);
    }));

    final element = document.body;
    rect = element.rect;
    computedStyle = element.computedStyle;
    expect(rect.isComplete, isFalse);
    expect(computedStyle.isComplete, isFalse);
  });

  // TODO(jacobr): add more tests that the results return by measurement
  // functions are correct.
}
