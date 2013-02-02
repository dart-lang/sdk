// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library wheel_event_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';


main() {

  useHtmlConfiguration();

  var userAgent = window.navigator.userAgent;

  // Lame platform-dependent check to validate that our assumptions about
  // which event is being used is correct.
  var wheelEvent = 'wheel';
  if (userAgent.contains("Opera", 0)) {
    wheelEvent = 'mousewheel';
  } else if (userAgent.contains("MSIE", 0)) {
    wheelEvent = 'mousewheel';
  } else if (userAgent.contains('Firefox')) {
    // FF appears to have recently added support for wheel.
    wheelEvent = 'wheel';
  } else if (userAgent.contains('WebKit', 0)) {
    wheelEvent = 'mousewheel';
  }

  test('wheelEvent', () {
    var element = new DivElement();
    element.onMouseWheel.listen(expectAsync1((e) {
      expect(e.screenX, 100);
      expect(e.deltaX, 0);
      expect(e.deltaY, 240);
    }));
    var event = new WheelEvent(wheelEvent,
      deltaX: 0,
      deltaY: 240,
      screenX: 100);
    element.dispatchEvent(event);
  });

  test('wheelEvent Stream', () {
    var element = new DivElement();
    element.onMouseWheel.listen(expectAsync1((e) {
      expect(e.screenX, 100);
      expect(e.deltaX, 0);
      expect(e.deltaY, 240);
    }));
    var event = new WheelEvent(wheelEvent,
      deltaX: 0,
      deltaY: 240,
      screenX: 100);
    element.dispatchEvent(event);
  });
}
