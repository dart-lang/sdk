// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library wheel_event_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  test('wheelEvent', () {
    var element = new DivElement();
    var eventType = Element.mouseWheelEvent.getEventType(element);

    element.onMouseWheel.listen(expectAsync((e) {
      expect(e.screen.x, 100);
      expect(e.deltaX, 0);
      expect(e.deltaY.toDouble(), 240.0);
      expect(e.deltaMode, WheelEvent.DOM_DELTA_PAGE);
    }));
    var event = new WheelEvent(eventType,
        deltaX: 0,
        deltaY: 240,
        deltaMode: WheelEvent.DOM_DELTA_PAGE,
        screenX: 100);
    element.dispatchEvent(event);
  });

  test('wheelEvent with deltaZ', () {
    var element = new DivElement();
    var eventType = Element.mouseWheelEvent.getEventType(element);

    element.onMouseWheel.listen(expectAsync((e) {
      expect(e.deltaX, 0);
      expect(e.deltaY, 0);
      expect(e.screen.x, 0);
      expect(e.deltaZ.toDouble(), 1.0);
    }));
    var event = new WheelEvent(eventType, deltaZ: 1.0);
    element.dispatchEvent(event);
  });

  test('wheelEvent Stream', () {
    var element = new DivElement();
    var eventType = Element.mouseWheelEvent.getEventType(element);

    element.onMouseWheel.listen(expectAsync((e) {
      expect(e.screen.x, 100);
      expect(e.deltaX.toDouble(), 240.0);
      expect(e.deltaY, 0);
    }));
    var event = new WheelEvent(eventType, deltaX: 240, deltaY: 0, screenX: 100);
    element.dispatchEvent(event);
  });
}
