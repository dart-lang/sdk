// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('EventCustomEventTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
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
    expect(fired, isTrue, 'Expected event to be dispatched.');
  });
}

main() {
  useHtmlConfiguration();

  eventTest('CustomEvent.initCustomEvent', () {
    // TODO: switch to constructors later.
    final ev = document.$dom_createEvent('CustomEvent');
    ev.initCustomEvent('foo', false, false, 'detail');
    return ev;
  },
  (ev) { expect(ev.detail, equals('detail')); });
}
