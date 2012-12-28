// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ElementWebKitTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';


// NOTE:
// These should ALL be webkit-specific items
// Ideally all of these should be functional on all browsers and moved into
// element_test.dart.

void testEventHelper(EventListenerList listenerList, type,
    [Function registerOnEventListener = null]) {
  bool firedWhenAddedToListenerList = false;
  bool firedOnEvent = false;
  listenerList.add((e) {
    firedWhenAddedToListenerList = true;
  });
  if (registerOnEventListener != null) {
    registerOnEventListener((e) {
      firedOnEvent = true;
    });
  }

  final event = new Event(type);
  listenerList.dispatch(event);

  expect(firedWhenAddedToListenerList, isTrue);
  if (registerOnEventListener != null) {
    expect(firedOnEvent, isTrue);
  }
}

main() {
  useHtmlConfiguration();


  group('events', () {
    final element = new Element.tag('div');
    final on = element.on;
    testEventHelper(on.transitionEnd, 'webkitTransitionEnd');
    testEventHelper(on.fullscreenChange, 'webkitfullscreenchange',
        (listener) => Testing.addEventListener(element,
            'webkitfullscreenchange', listener, true));
  });
}



