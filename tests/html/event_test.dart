// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('EventTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

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
    Expect.isTrue(fired, 'Expected event to be dispatched.');
  });
}

main() {
  useHtmlConfiguration();

  // Issue 1005.
  // eventTest('AnimationEvent', () => new AnimationEvent('foo', 'color', 0.5),
  //     (ev) {
  //   Expect.equals('color', ev.animationName);
  //   Expect.equals(0.5, ev.elapsedTime);
  // });

  // Issue 1005.
  // eventTest('BeforeLoadEvent',
  //    () => new BeforeLoadEvent('foo', 'http://example.url'),
  //    (ev) { Expect.equals('http://example.url', ev.url); });

  // Issue 1005.
  // eventTest('CloseEvent',
  //     () => new CloseEvent('foo', 5, 'reason', wasClean: true),
  //     (ev) {
  //   Expect.equals(5, ev.code);
  //   Expect.equals('reason', ev.reason);
  //   Expect.isTrue(ev.wasClean);
  // });

  eventTest('CompositionEvent',
      () => new CompositionEvent('compositionstart', window, 'data'),
      (ev) { Expect.equals('data', ev.data); },
      type: 'compositionstart');

  // initCustomEvent is not yet implemented
  // eventTest('CustomEvent',
  //     () => new CustomEvent('foo', false, false, 'detail'),
  //     (ev) { Expect.equals('detail', ev.detail); });

  // DeviceMotionEvent has no properties to itself, so just test that it doesn't
  // error out on creation and can be dispatched.
  eventTest('DeviceMotionEvent', () => new DeviceMotionEvent('foo'), (ev) {});

  // initDeviceOrientationEvent is not yet implemented
  // eventTest('DeviceOrientationEvent',
  //     () => new DeviceOrientationEvent('foo', 0.1, 0.2, 0.3),
  //     (ev) {
  //   Expect.equals(0.1, ev.alpha);
  //   Expect.equals(0.2, ev.beta);
  //   Expect.equals(0.3, ev.gamma);
  // });

  // Issue 1005.
  // eventTest('ErrorEvent',
  //     () => new ErrorEvent('foo', 'message', 'filename', 10),
  //     (ev) {
  //   Expect.equals('message', ev.message);
  //   Expect.equals('filename', ev.filename);
  //   Expect.equals(10, ev.lineno);
  // });

  eventTest('Event',
      () => new Event('foo', canBubble: false, cancelable: false),
      (ev) {
    Expect.equals('foo', ev.type);
    Expect.isFalse(ev.bubbles);
    Expect.isFalse(ev.cancelable);
  });

  eventTest('HashChangeEvent',
      () => new HashChangeEvent('foo', 'http://old.url', 'http://new.url'),
      (ev) {
    Expect.equals('http://old.url', ev.oldURL);
    Expect.equals('http://new.url', ev.newURL);
  });

  eventTest('KeyboardEvent',
      () => new KeyboardEvent('foo', window, 'key', 10, ctrlKey: true,
          altKey: true, shiftKey: true, metaKey: true, altGraphKey: true),
      (ev) {
    Expect.equals('key', ev.keyIdentifier);
    Expect.equals(10, ev.keyLocation);
    Expect.isTrue(ev.ctrlKey);
    Expect.isTrue(ev.altKey);
    Expect.isTrue(ev.shiftKey);
    Expect.isTrue(ev.metaKey);
    Expect.isTrue(ev.altGraphKey);
  });

  eventTest('MouseEvent',
      // canBubble and cancelable are currently required to avoid dartc
      // complaining about the types of the named arguments.
      () => new MouseEvent('foo', window, 1, 2, 3, 4, 5, 6, canBubble: true,
          cancelable: true, ctrlKey: true, altKey: true, shiftKey: true,
          metaKey: true, relatedTarget: new Element.tag('div')),
      (ev) {
    Expect.equals(1, ev.detail);
    Expect.equals(2, ev.screenX);
    Expect.equals(3, ev.screenY);
    Expect.equals(4, ev.clientX);
    Expect.equals(5, ev.clientY);
    Expect.equals(4, ev.offsetX);  // Same as clientX.
    Expect.equals(5, ev.offsetY);  // Same as clientY.
    Expect.equals(6, ev.button);
    Expect.isTrue(ev.ctrlKey);
    Expect.isTrue(ev.altKey);
    Expect.isTrue(ev.shiftKey);
    Expect.isTrue(ev.metaKey);
    Expect.equals('DIV', ev.relatedTarget.tagName);
  });

  eventTest('MutationEvent',
      () => new MutationEvent('foo', new Element.tag('div'), 'red', 'blue',
          'color', MutationEvent.MODIFICATION),
      (ev) {
    Expect.equals('DIV', ev.relatedNode.tagName);
    Expect.equals('red', ev.prevValue);
    Expect.equals('blue', ev.newValue);
    Expect.equals('color', ev.attrName);
    Expect.equals(MutationEvent.MODIFICATION, ev.attrChange);
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
  //   Expect.equals(OverflowEvent.BOTH, ev.orient);
  //   Expect.isTrue(ev.horizontalOverflow);
  //   Expect.isTrue(ev.verticalOverflow);
  // }, type: 'overflowchanged');

  // Issue 1005.
  // eventTest('PageTransitionEvent',
  //     () => new PageTransitionEvent('foo', persisted: true),
  //     (ev) { Expect.isTrue(ev.persisted); });

  // initPopStateEvent is not yet implemented
  // eventTest('PopStateEvent', () => new PopStateEvent('foo', 'state'),
  //     (ev) { Expect.equals('state', ev.state); }

  // Issue 1005.
  // eventTest('ProgressEvent',
  //     // canBubble and cancelable are currently required to avoid dartc
  //     // complaining about the types of the named arguments.
  //     () => new ProgressEvent('foo', 5, canBubble: true, cancelable: true,
  //         lengthComputable: true, total: 10),
  //     (ev) {
  //   Expect.equals(5, ev.loaded);
  //   Expect.isTrue(ev.lengthComputable);
  //   Expect.equals(10, ev.total);
  // });

  eventTest('StorageEvent',
      () => new StorageEvent('foo', 'key', 'http://example.url',
          window.localStorage, canBubble: true, cancelable: true,
          oldValue: 'old', newValue: 'new'),
      (ev) {
    Expect.equals('key', ev.key);
    Expect.equals('http://example.url', ev.url);
    // Equality isn't preserved for storageArea
    Expect.isNotNull(ev.storageArea);
    Expect.equals('old', ev.oldValue);
    Expect.equals('new', ev.newValue);
  });

  eventTest('TextEvent', () => new TextEvent('foo', window, 'data'),
      (ev) { Expect.equals('data', ev.data); });

  // Issue 1005.
  // eventTest('TransitionEvent', () => new TransitionEvent('foo', 'color', 0.5),
  //     (ev) {
  //   Expect.equals('color', ev.propertyName);
  //   Expect.equals(0.5, ev.elapsedTime);
  // });

  eventTest('UIEvent', () => new UIEvent('foo', window, 12),
      (ev) {
    Expect.equals(window, ev.view);
    Expect.equals(12, ev.detail);
  });

  eventTest('WheelEvent',
      () => new WheelEvent(1, 2, window, 3, 4, 5, 6, ctrlKey: true,
          altKey: true, shiftKey: true, metaKey: true),
      (ev) {
    // wheelDelta* properties are multiplied by 120 for some reason
    Expect.equals(120, ev.wheelDeltaX);
    Expect.equals(240, ev.wheelDeltaY);
    Expect.equals(3, ev.screenX);
    Expect.equals(4, ev.screenY);
    Expect.equals(5, ev.clientX);
    Expect.equals(6, ev.clientY);
    Expect.isTrue(ev.ctrlKey);
    Expect.isTrue(ev.altKey);
    Expect.isTrue(ev.shiftKey);
    Expect.isTrue(ev.metaKey);
  }, type: 'mousewheel');

  // HttpRequestProgressEvent has no properties to itself, so just test that
  // it doesn't error out on creation and can be dispatched.
  // Issue 1005.
  // eventTest('HttpRequestProgressEvent',
  //     () => new HttpRequestProgressEvent('foo', 5),
  //     (ev) {});
}
