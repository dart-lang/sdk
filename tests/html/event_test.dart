// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library EventTest;

import "package:expect/expect.dart";
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

// TODO(nweiz): Make this private to testEvents when Frog supports closures with
// optional arguments.
eventTest(String name, Event eventFn(), void validate(Event),
    [String type = 'foo']) {
  test(name, () {
    final el = new Element.tag('div');
    var fired = false;
    el.on[type].listen((ev) {
      fired = true;
      validate(ev);
    });
    el.dispatchEvent(eventFn());
    expect(fired, isTrue, reason: 'Expected event to be dispatched.');
  });
}

main() {
  useHtmlConfiguration();

  // Issue 1005.
  // eventTest('AnimationEvent', () => new AnimationEvent('foo', 'color', 0.5),
  //     (ev) {
  //   expect(ev.animationName, 'color');
  //   expect(ev.elapsedTime, 0.5);
  // });

  // Issue 1005.
  // eventTest('BeforeLoadEvent',
  //    () => new BeforeLoadEvent('foo', 'http://example.url'),
  //    (ev) { expect(ev.url, 'http://example.url'); });

  // Issue 1005.
  // eventTest('CloseEvent',
  //     () => new CloseEvent('foo', 5, 'reason', wasClean: true),
  //     (ev) {
  //   expect(ev.code, 5);
  //   expect(ev.reason, 'reason');
  //   expect(ev.wasClean, isTrue);
  // });

  eventTest(
      'CompositionEvent',
      () =>
          new CompositionEvent('compositionstart', view: window, data: 'data'),
      (ev) {
    expect(ev.data, 'data');
  }, 'compositionstart');

  // initCustomEvent is not yet implemented
  // eventTest('CustomEvent',
  //     () => new CustomEvent('foo', false, false, 'detail'),
  //     (ev) { expect(ev.detail, 'detail'); });

  // DeviceMotionEvent has no properties to itself, so just test that it doesn't
  // error out on creation and can be dispatched.
  // Suppress. DeviceMotion has no constructor, and I don't think it can be
  // created on a non-mobile device. Issue 23321
  // eventTest('DeviceMotionEvent', () => new DeviceMotionEvent('foo'), (ev) {});

  // initDeviceOrientationEvent is not yet implemented
  // eventTest('DeviceOrientationEvent',
  //     () => new DeviceOrientationEvent('foo', 0.1, 0.2, 0.3),
  //     (ev) {
  //   expect(ev.alpha, 0.1);
  //   expect(ev.beta, 0.2);
  //   expect(ev.gamma, 0.3);
  // });

  // Issue 1005.
  // eventTest('ErrorEvent',
  //     () => new ErrorEvent('foo', 'message', 'filename', 10),
  //     (ev) {
  //   expect('message', ev.message);
  //   expect('filename', ev.filename);
  //   expect(ev.lineno, 10);
  // });

  eventTest(
      'Event', () => new Event('foo', canBubble: false, cancelable: false),
      (ev) {
    expect(ev.type, equals('foo'));
    expect(ev.bubbles, isFalse);
    expect(ev.cancelable, isFalse);
  });

  eventTest(
      'HashChangeEvent',
      () => new HashChangeEvent('foo',
          oldUrl: 'http://old.url', newUrl: 'http://new.url'), (ev) {
    expect(ev.oldUrl, equals('http://old.url'));
    expect(ev.newUrl, equals('http://new.url'));
  });

  // KeyboardEvent has its own test file, and has cross-browser issues.

  eventTest(
      'MouseEvent',
      () => new MouseEvent('foo',
          view: window,
          detail: 1,
          screenX: 2,
          screenY: 3,
          clientX: 4,
          clientY: 5,
          button: 6,
          ctrlKey: true,
          altKey: true,
          shiftKey: true,
          metaKey: true,
          relatedTarget: document.body), (ev) {
    expect(ev.detail, 1);
    expect(ev.screen.x, 2);
    expect(ev.screen.y, 3);
    expect(ev.client.x, 4);
    expect(ev.client.y, 5);
    expect(ev.offset.x, 4); // Same as clientX.
    expect(ev.offset.y, 5); // Same as clientY.
    expect(ev.button, 6);
    expect(ev.ctrlKey, isTrue);
    expect(ev.altKey, isTrue);
    expect(ev.shiftKey, isTrue);
    expect(ev.metaKey, isTrue);
    // TODO(alanknight): The target does not seem to get correctly set.
    // Issue 23438
    //  expect(ev.relatedTarget, document.body);
  });

  // Issue 1005.
  // eventTest('OverflowEvent',
  //     () => new OverflowEvent(OverflowEvent.BOTH, true, true),
  //     (ev) {
  //   expect(ev.orient, OverflowEvent.BOTH);
  //   expect(ev.horizontalOverflow, isTrue);
  //   expect(ev.verticalOverflow, isTrue);
  // }, type: 'overflowchanged');

  // Issue 1005.
  // eventTest('PageTransitionEvent',
  //     () => new PageTransitionEvent('foo', persisted: true),
  //     (ev) { expect(ev.persisted, isTrue); });

  // initPopStateEvent is not yet implemented
  // eventTest('PopStateEvent', () => new PopStateEvent('foo', 'state'),
  //     (ev) { expect(ev.state, 'state'); }

  // Issue 1005.
  // eventTest('ProgressEvent',
  //     // canBubble and cancelable are currently required to avoid dartc
  //     // complaining about the types of the named arguments.
  //     () => new ProgressEvent('foo', 5, canBubble: true, cancelable: true,
  //         lengthComputable: true, total: 10),
  //     (ev) {
  //   expect(ev.loaded, 5);
  //   expect(ev.lengthComputable, isTrue);
  //   expect(ev.total, 10);
  // });

  eventTest(
      'StorageEvent',
      () => new StorageEvent('foo',
          key: 'key',
          url: 'http://example.url',
          storageArea: window.localStorage,
          canBubble: true,
          cancelable: true,
          oldValue: 'old',
          newValue: 'new'), (ev) {
    expect(ev.key, 'key');
    expect(ev.url, 'http://example.url');
    // Equality isn't preserved for storageArea
    expect(ev.storageArea, isNotNull);
    expect(ev.oldValue, 'old');
    expect(ev.newValue, 'new');
  });

  // Issue 1005.
  // eventTest('TransitionEvent', () => new TransitionEvent('foo', 'color', 0.5),
  //     (ev) {
  //   expect(ev.propertyName, 'color');
  //   expect(ev.elapsedTime, 0.5);
  // });

  eventTest('UIEvent', () => new UIEvent('foo', view: window, detail: 12),
      (ev) {
    expect(window, ev.view);
    expect(12, ev.detail);
  });

  eventTest(
      'WheelEvent',
      // TODO(alanknight): Can't pass window on Dartium. Add view: window
      // once going through JS.
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
  }, 'mousewheel');
}
