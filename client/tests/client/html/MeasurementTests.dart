// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void testMeasurement() { 
  asyncTest('measurement is async but before setTimout 0', 1, () {
    final element = document.body;
    bool timeout0 = false;
    bool fnComplete = false;
    bool animationFrame = false;
    window.setTimeout(() { timeout0 = true; }, 0);
    final computedStyle = element.computedStyle;
    computedStyle.then((style) {
      Expect.equals(style.getPropertyValue('left'), 'auto');
      Expect.isTrue(fnComplete);
      Expect.isFalse(timeout0);
      Expect.isFalse(animationFrame);
      callbackDone();
    });
    Expect.isFalse(computedStyle.isComplete);
    fnComplete = true;
  });

  asyncTest('requestLayoutFrame', 1, () {
    var rect;
    var computedStyle;
    window.requestLayoutFrame(() {
      Expect.isTrue(rect.isComplete);
      Expect.isTrue(computedStyle.isComplete);
      callbackDone();
    });

    final element = document.body;
    rect = element.rect;
    computedStyle = element.computedStyle;
    Expect.isFalse(rect.isComplete);
    Expect.isFalse(computedStyle.isComplete);
  });

  // TODO(jacobr): add more tests that the results return by measurement
  // functions are correct.
}
