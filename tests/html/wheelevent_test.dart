// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library wheel_event_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';


main() {

  useHtmlConfiguration();

  test('wheelEvent', () {
    var element = new DivElement();
    var eventType = Element.mouseWheelEvent.getEventType(element);

    element.onMouseWheel.listen(expectAsync1((e) {
      expect(e.screen.x, 100);
      expect(e.deltaX, 0);
      expect(e.deltaY, 240);
      expect(e.deltaMode, isNotNull);
    }));
    var event = new WheelEvent(eventType,
      deltaX: 0,
      deltaY: 240,
      screenX: 100);
    element.dispatchEvent(event);
  });

  test('wheelEvent Stream', () {
    var element = new DivElement();
    var eventType = Element.mouseWheelEvent.getEventType(element);

    element.onMouseWheel.listen(expectAsync1((e) {
      expect(e.screen.x, 100);
      expect(e.deltaX, 0);
      expect(e.deltaY, 240);
    }));
    var event = new WheelEvent(eventType,
      deltaX: 0,
      deltaY: 240,
      screenX: 100);
    element.dispatchEvent(event);
  });
}
