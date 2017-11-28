// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tests.html.events_test;

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

main() {
  useHtmlConfiguration();

  test('TimeStamp', () {
    Event event = new Event('test');

    int timeStamp = event.timeStamp;
    expect(timeStamp, greaterThan(0));
  });

  test('Event canBubble and cancelable', () {
    // Try every combination of canBubble and cancelable
    for (var i = 0; i < 4; i++) {
      var bubble = (i & 1) != 0;
      var cancel = (i & 2) != 0;
      var e = new Event('input', canBubble: bubble, cancelable: cancel);
      expect(e.bubbles, bubble, reason: 'canBubble was set to $bubble');
      expect(e.cancelable, cancel, reason: 'cancelable was set to $cancel');
    }
  });

  // The next test is not asynchronous because [on['test'].dispatch(event)] fires the event
  // and event listener synchronously.
  test('EventTarget', () {
    Element element = new Element.tag('test');
    element.id = 'eventtarget';
    window.document.body.append(element);

    int invocationCounter = 0;
    void handler(Event e) {
      expect(e.type, equals('test'));
      Element target = e.target;
      expect(element, equals(target));
      invocationCounter++;
    }

    Event event = new Event('test');

    invocationCounter = 0;
    element.dispatchEvent(event);
    expect(invocationCounter, isZero);

    var provider = new EventStreamProvider<Event>('test');

    var sub = provider.forTarget(element).listen(handler);
    invocationCounter = 0;
    element.dispatchEvent(event);
    expect(invocationCounter, 1);

    sub.cancel();
    invocationCounter = 0;
    element.dispatchEvent(event);
    expect(invocationCounter, isZero);

    provider.forTarget(element).listen(handler);
    invocationCounter = 0;
    element.dispatchEvent(event);
    expect(invocationCounter, 1);

    provider.forTarget(element).listen(handler);
    invocationCounter = 0;
    element.dispatchEvent(event);

    // NOTE: when run in a custom zone, the handler is wrapped
    // The logic for html events which ensures identical handlers are added only
    // once is therefor muted by the wrapped handlers.
    // Hence, we get different behavior depending on the current zone.
    if (Zone.current == Zone.root) {
      expect(invocationCounter, 1);
    } else {
      expect(invocationCounter, 2);
    }
  });

  test('InitMouseEvent', () {
    DivElement div = new Element.tag('div');
    MouseEvent event = new MouseEvent('zebra', relatedTarget: div);
  });

  test('DOM event callbacks are associated with the correct zone', () {
    var callbacks = [];

    final element = new Element.tag('test');
    element.id = 'eventtarget';
    document.body.append(element);

    // runZoned executes the function synchronously, but we don't want to
    // rely on this. We therefore wrap it into an expectAsync.
    runZoned(expectAsync(() {
      Zone zone = Zone.current;
      expect(zone, isNot(equals(Zone.root)));

      var sub;

      void handler(Event e) {
        expect(Zone.current, equals(zone));

        scheduleMicrotask(expectAsync(() {
          expect(Zone.current, equals(zone));
          sub.cancel();
        }));
      }

      sub = element.on['test'].listen(expectAsync(handler));
    }));
    element.dispatchEvent(new Event('test'));
  });
}
