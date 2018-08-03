// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library wheel_event_test;

import 'dart:async';
import 'dart:html';

import 'package:expect/minitest.dart';

Future testWheelEvent() async {
  final done = new Completer();
  var element = new DivElement();
  var eventType = Element.mouseWheelEvent.getEventType(element);

  element.onMouseWheel.listen((e) {
    try {
      expect(e.screen.x, 100);
      expect(e.deltaX, 0);
      expect(e.deltaY.toDouble(), 240.0);
      expect(e.deltaMode, WheelEvent.DOM_DELTA_PAGE);
      done.complete();
    } catch (e) {
      done.completeError(e);
    }
  });
  var event = new WheelEvent(eventType,
      deltaX: 0,
      deltaY: 240,
      deltaMode: WheelEvent.DOM_DELTA_PAGE,
      screenX: 100);
  element.dispatchEvent(event);
  await done.future;
}

Future testWheelEventWithDeltaZ() async {
  final done = new Completer();
  var element = new DivElement();
  var eventType = Element.mouseWheelEvent.getEventType(element);

  element.onMouseWheel.listen((e) {
    try {
      expect(e.deltaX, 0);
      expect(e.deltaY, 0);
      expect(e.screen.x, 0);
      expect(e.deltaZ.toDouble(), 1.0);
      done.complete();
    } catch (e) {
      done.completeError(e);
    }
  });
  var event = new WheelEvent(eventType, deltaZ: 1.0);
  element.dispatchEvent(event);
  await done.future;
}

Future testWheelEventStream() async {
  final done = new Completer();
  var element = new DivElement();
  var eventType = Element.mouseWheelEvent.getEventType(element);

  element.onMouseWheel.listen((e) {
    try {
      expect(e.screen.x, 100);
      expect(e.deltaX.toDouble(), 240.0);
      expect(e.deltaY, 0);
      done.complete();
    } catch (e) {
      done.completeError(e);
    }
  });
  var event = new WheelEvent(eventType, deltaX: 240, deltaY: 0, screenX: 100);
  element.dispatchEvent(event);
  await done.future;
}

main() async {
  await testWheelEvent();
  await testWheelEventWithDeltaZ();
  await testWheelEventStream();
}
