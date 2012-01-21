// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void testMeasurement() { 
  asyncTest('measurement is async but before setTimout 0', 1, () {
    final element = document.body;
    bool timeout0 = false;
    bool fnComplete = false;
    bool animationFrame = false;
    bool callbackComplete = false;
    window.setTimeout(() { timeout0 = true; }, 0);
    window.requestMeasurementFrame(() {
      callbackComplete = true;
      final style = element.computedStyle;
      Expect.equals(style.getPropertyValue('left'), 'auto');
      Expect.isTrue(fnComplete);
      Expect.isFalse(timeout0);
      Expect.isFalse(animationFrame);
      return callbackDone;
    });
    Expect.isFalse(callbackComplete);
    fnComplete = true;
  });

  // TODO(jacobr): add more tests that the results return by measurement
  // functions are correct.

  // TODO(jacobr): add tests that the dom cannot be manipulated while layout
  // is in progress and measurement cannot be performed unless
  // requestMeasurementFrame is called.
}
