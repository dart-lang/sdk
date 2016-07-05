// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library EventTaskZoneTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:async';
import 'dart:html';

// Tests zone tasks with DOM events.

class AbortedEventStreamSubscription implements StreamSubscription<Event> {
  final Zone zone;

  AbortedEventStreamSubscription(this.zone);

  @override
  Future asFuture([futureValue]) {
    throw new UnsupportedError("asFuture");
  }

  @override
  Future cancel() {
    return null;
  }

  @override
  bool get isPaused => throw new UnsupportedError("pause");

  @override
  void onData(void handleData(Event data)) {
    throw new UnsupportedError("cancel");
  }

  @override
  void onDone(void handleDone()) {
    throw new UnsupportedError("onDone");
  }

  @override
  void onError(Function handleError) {
    throw new UnsupportedError("onError");
  }

  @override
  void pause([Future resumeSignal]) {
    throw new UnsupportedError("pause");
  }

  @override
  void resume() {
    throw new UnsupportedError("resume");
  }

  static AbortedEventStreamSubscription _create(
      EventSubscriptionSpecification spec, Zone zone) {
    return new AbortedEventStreamSubscription(zone);
  }
}

eventTest(String name, Event eventFn(), void validate(Event event),
    void validateSpec(EventSubscriptionSpecification spec),
    {String type: 'foo',
    bool abortCreation: false,
    EventSubscriptionSpecification modifySpec(
        EventSubscriptionSpecification spec),
    bool abortEvent: false,
    Event modifyEvent(Event event)}) {
  test(name, () {
    var lastSpec;
    var lastTask;
    var lastEvent;

    Object createTaskHandler(Zone self, ZoneDelegate parent, Zone zone,
        TaskCreate create, TaskSpecification specification) {
      if (specification is EventSubscriptionSpecification) {
        if (abortCreation) {
          create = AbortedEventStreamSubscription._create;
        }
        if (modifySpec != null) {
          specification = modifySpec(specification);
        }
        lastSpec = specification;
        return lastTask = parent.createTask(zone, create, specification);
      }
      return parent.createTask(zone, create, specification);
    }

    void runTaskHandler(Zone self, ZoneDelegate parent, Zone zone, TaskRun run,
        Object task, Object arg) {
      if (identical(task, lastTask)) {
        if (abortEvent) return;
        if (modifyEvent != null) {
          arg = modifyEvent(arg);
        }
        parent.runTask(zone, run, task, arg);
        return;
      }
      parent.runTask(zone, run, task, arg);
    }

    runZoned(() {
      final el = new Element.tag('div');
      var fired = false;
      var sub = el.on[type].listen((ev) {
        lastEvent = ev;
        fired = true;
      });
      el.dispatchEvent(eventFn());

      validateSpec(lastSpec);
      validate(lastEvent);

      if (abortEvent || abortCreation) {
        expect(fired, isFalse, reason: 'Expected event to be intercepted.');
      } else {
        expect(fired, isTrue, reason: 'Expected event to be dispatched.');
      }

      sub.cancel();
    },
        zoneSpecification: new ZoneSpecification(
            createTask: createTaskHandler,
            runTask: runTaskHandler));
  });
}

Function checkSpec(
    [String expectedType = 'foo', bool expectedUseCapture = false]) {
  return (EventSubscriptionSpecification spec) {
    expect(spec.eventType, expectedType);
    expect(spec.useCapture, expectedUseCapture);
  };
}

main() {
  useHtmlConfiguration();

  eventTest('Event', () => new Event('foo'), (ev) {
    expect(ev.type, equals('foo'));
  }, checkSpec('foo'));

  eventTest(
      'WheelEvent',
      () => new WheelEvent("mousewheel",
          deltaX: 1,
          deltaY: 0,
          detail: 4,
          screenX: 3,
          screenY: 4,
          clientX: 5,
          clientY: 6,
          ctrlKey: true,
          altKey: true,
          shiftKey: true,
          metaKey: true), (ev) {
    expect(ev.deltaX, 1);
    expect(ev.deltaY, 0);
    expect(ev.screen.x, 3);
    expect(ev.screen.y, 4);
    expect(ev.client.x, 5);
    expect(ev.client.y, 6);
    expect(ev.ctrlKey, isTrue);
    expect(ev.altKey, isTrue);
    expect(ev.shiftKey, isTrue);
    expect(ev.metaKey, isTrue);
  }, checkSpec('mousewheel'), type: 'mousewheel');

  eventTest('Event - no-create', () => new Event('foo'), (ev) {
    expect(ev, isNull);
  }, checkSpec('foo'), abortCreation: true);

  eventTest(
      'WheelEvent - no-create',
      () => new WheelEvent("mousewheel",
          deltaX: 1,
          deltaY: 0,
          detail: 4,
          screenX: 3,
          screenY: 4,
          clientX: 5,
          clientY: 6,
          ctrlKey: true,
          altKey: true,
          shiftKey: true,
          metaKey: true), (ev) {
    expect(ev, isNull);
  }, checkSpec('mousewheel'), type: 'mousewheel', abortCreation: true);

  eventTest('Event - no-run', () => new Event('foo'), (ev) {
    expect(ev, isNull);
  }, checkSpec('foo'), abortEvent: true);

  eventTest(
      'WheelEvent - no-run',
      () => new WheelEvent("mousewheel",
          deltaX: 1,
          deltaY: 0,
          detail: 4,
          screenX: 3,
          screenY: 4,
          clientX: 5,
          clientY: 6,
          ctrlKey: true,
          altKey: true,
          shiftKey: true,
          metaKey: true), (ev) {
    expect(ev, isNull);
  }, checkSpec('mousewheel'), type: 'mousewheel', abortEvent: true);

  // Register for 'foo', but receive a 'bar' event, because the specification
  // is rewritten.
  eventTest(
      'Event - replace eventType',
      () => new Event('bar'),
      (ev) {
        expect(ev.type, equals('bar'));
      },
      checkSpec('bar'),
      type: 'foo',
      modifySpec: (EventSubscriptionSpecification spec) {
        return spec.replace(eventType: 'bar');
      });

  // Intercept the 'foo' event and replace it with a 'bar' event.
  eventTest(
      'Event - intercept result',
      () => new Event('foo'),
      (ev) {
        expect(ev.type, equals('bar'));
      },
      checkSpec('foo'),
      type: 'foo',
      modifyEvent: (Event event) {
        return new Event('bar');
      });
}
