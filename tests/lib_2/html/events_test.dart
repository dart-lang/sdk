// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tests.html.events_test;

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/src/expected_function.dart' show ExpectedFunction;

T Function() expectAsync0<T>(T Function() callback,
        {int count: 1, int max: 0}) =>
    new ExpectedFunction<T>(callback, count, max).max0;

T Function(A) expectAsync1<T, A>(T Function(A) callback,
        {int count: 1, int max: 0}) =>
    new ExpectedFunction<T>(callback, count, max).max1;

main() {
  useHtmlConfiguration();

  test('TimeStamp', () {
    var event = new Event('test');

    var timeStamp = event.timeStamp;
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
    var element = new Element.tag('test');
    element.id = 'eventtarget';
    document.body.append(element);

    var invocationCounter = 0;
    void handler(Event e) {
      expect(e.type, equals('test'));
      var target = e.target;
      expect(element, equals(target));
      invocationCounter++;
    }

    var event = new Event('test');

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
    var div = new Element.tag('div');
    var event = new MouseEvent('zebra', relatedTarget: div);
  });

  test('DOM event callbacks are associated with the correct zone', () {
    var callbacks = [];

    var element = new Element.tag('test');
    element.id = 'eventtarget';
    document.body.append(element);

    // runZoned executes the function synchronously, but we don't want to
    // rely on this. We therefore wrap it into an expectAsync.
    runZoned(expectAsync0(() {
      var zone = Zone.current;
      expect(zone, isNot(equals(Zone.root)));

      StreamSubscription<Event> sub;

      void handler(Event e) {
        expect(Zone.current, equals(zone));

        scheduleMicrotask(expectAsync0(() {
          expect(Zone.current, equals(zone));
          sub.cancel();
        }));
      }

      sub = element.on['test'].listen(expectAsync1(handler));
    }));
    element.dispatchEvent(new Event('test'));
  });
}
