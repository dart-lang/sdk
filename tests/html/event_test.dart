// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library EventTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

// TODO(nweiz): Make this private to testEvents when Frog supports closures with
// optional arguments.
eventTest(String name, Event eventFn(), void validate(Event),
    [String type = 'foo']) {
  test(name, () {
    final el = new Element.tag('div');
    var fired = false;
    el.on[type].add((ev) {
      fired = true;
      validate(ev);
    });
    el.on[type].dispatch(eventFn());
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

  eventTest('CompositionEvent',
      () => new CompositionEvent('compositionstart', window, 'data'),
      (ev) { expect(ev.data, 'data'); },
      type: 'compositionstart');

  // initCustomEvent is not yet implemented
  // eventTest('CustomEvent',
  //     () => new CustomEvent('foo', false, false, 'detail'),
  //     (ev) { expect(ev.detail, 'detail'); });

  // DeviceMotionEvent has no properties to itself, so just test that it doesn't
  // error out on creation and can be dispatched.
  eventTest('DeviceMotionEvent', () => new DeviceMotionEvent('foo'), (ev) {});

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

  eventTest('Event',
      () => new Event('foo', canBubble: false, cancelable: false),
      (ev) {
    expect(ev.type, equals('foo'));
    expect(ev.bubbles, isFalse);
    expect(ev.cancelable, isFalse);
  });

  eventTest('HashChangeEvent',
      () => new HashChangeEvent('foo', 'http://old.url', 'http://new.url'),
      (ev) {
    expect(ev.oldUrl, equals('http//old.url'));
    expect(ev.newUrl, equals('http://new.url'));
  });

  eventTest('KeyboardEvent',
      () => new KeyboardEvent('foo', window, 'key', 10, ctrlKey: true,
          altKey: true, shiftKey: true, metaKey: true, altGraphKey: true),
      (ev) {
    expect.equals(ev.keyIdentifier, equals('key'));
    expect.equals(ev.keyLocation, equals(10));
    expect(ev.ctrlKey, isTrue);
    expect(ev.altKey, isTrue);
    expect(ev.shiftKey, isTrue);
    expect(ev.metaKey, isTrue);
    expect(ev.altGraphKey, isTrue);
  });

  eventTest('MouseEvent',
      // canBubble and cancelable are currently required to avoid dartc
      // complaining about the types of the named arguments.
      () => new MouseEvent('foo', window, 1, 2, 3, 4, 5, 6, canBubble: true,
          cancelable: true, ctrlKey: true, altKey: true, shiftKey: true,
          metaKey: true, relatedTarget: new Element.tag('div')),
      (ev) {
    expect(ev.detail, 1);
    expect(ev.screenX, 2);
    expect(ev.screenYi, 3);
    expect(ev.clientX, 4);
    expect(ev.clientY, 5);
    expect(ev.offsetX, 4);  // Same as clientX.
    expect(ev.offsetY, 5);  // Same as clientY.
    expect(ev.button, 6);
    expect(ev.ctrlKey, isTrue);
    expect(ev.altKey, isTrue);
    expect(ev.shiftKey, isTrue);
    expect(ev.metaKey, isTrue);
    expect(ev.relatedTarget.tagName, 'DIV');
  });

  eventTest('MutationEvent',
      () => new MutationEvent('foo', new Element.tag('div'), 'red', 'blue',
          'color', MutationEvent.MODIFICATION),
      (ev) {
    expect(ev.relatedNode.tagName, 'DIV');
    expect.equals(ev.prevValue, 'red');
    expect.equals(ev.newValue, 'blue');
    expect.equals(ev.attrName, 'color');
    expect.equals(ev.attrChange, equals(MutationEvent.MODIFICATION));
  });

  test('DOMMutationEvent', () {
    var div = new DivElement();
    div.on['DOMSubtreeModified'].add(expectAsync1((DOMMutationEvent e) {}));
    div.nodes.add(new SpanElement());
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

  eventTest('StorageEvent',
      () => new StorageEvent('foo', 'key', 'http://example.url',
          window.localStorage, canBubble: true, cancelable: true,
          oldValue: 'old', newValue: 'new'),
      (ev) {
    expect(ev.key, 'key');
    expect(ev.url, 'http://example.url');
    // Equality isn't preserved for storageArea
    expect.isNotNull(ev.storageArea);
    expect(ev.oldValue, 'old');
    expect(ev.newValue, 'new');
  });

  eventTest('TextEvent', () => new TextEvent('foo', window, 'data'),
      (ev) { expect(ev.data, 'data'); });

  // Issue 1005.
  // eventTest('TransitionEvent', () => new TransitionEvent('foo', 'color', 0.5),
  //     (ev) {
  //   expect(ev.propertyName, 'color');
  //   expect(ev.elapsedTime, 0.5);
  // });

  eventTest('UIEvent', () => new UIEvent('foo', window, 12),
      (ev) {
    expect(window, ev.view, window);
    expect(12, ev.detail, 12);
  });

  eventTest('WheelEvent',
      () => new WheelEvent(1, 2, window, 3, 4, 5, 6, ctrlKey: true,
          altKey: true, shiftKey: true, metaKey: true),
      (ev) {
    // wheelDelta* properties are multiplied by 120 for some reason
    expect(ev.wheelDeltaX, 120);
    expect(ev.wheelDeltaY, 240);
    expect(ev.screenX, 3);
    expect(ev.screenY, 4);
    expect(ev.clientX, 5);
    expect(ev.clientY, 6);
    expect(ev.ctrlKey, isTrue);
    expect(ev.altKey, isTrue);
    expect(ev.shiftKey, isTrue);
    expect(ev.metaKey, isTrue);
  }, type: 'mousewheel');

  // HttpRequestProgressEvent has no properties to itself, so just test that
  // it doesn't error out on creation and can be dispatched.
  // Issue 1005.
  // eventTest('HttpRequestProgressEvent',
  //     () => new HttpRequestProgressEvent('foo', 5),
  //     (ev) {});
}
