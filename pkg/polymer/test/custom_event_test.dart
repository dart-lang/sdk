// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.web.custom_event_test;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';


@CustomTag('foo-bar')
class FooBar extends PolymerElement {
  // A little too much boilerplate?
  static const EventStreamProvider<CustomEvent> fooEvent =
      const EventStreamProvider<CustomEvent>('foo');
  static const EventStreamProvider<CustomEvent> barBazEvent =
      const EventStreamProvider<CustomEvent>('barbaz');

  FooBar.created() : super.created();

  Stream<CustomEvent> get onFooEvent =>
      FooBar.fooEvent.forTarget(this);
  Stream<CustomEvent> get onBarBazEvent =>
      FooBar.barBazEvent.forTarget(this);

  fireFoo(x) => dispatchEvent(new CustomEvent('foo', detail: x));
  fireBarBaz(x) => dispatchEvent(new CustomEvent('barbaz', detail: x));
}

@CustomTag('test-custom-event')
class TestCustomEvent extends PolymerElement {
  TestCustomEvent.created() : super.created();

  get fooBar => getShadowRoot('test-custom-event').query('foo-bar');

  final events = [];
  fooHandler(e) => events.add(['foo', e]);
  barBazHandler(e) => events.add(['barbaz', e]);
}

main() {
  initPolymer();
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('custom event', () {
    final testComp = query('test-custom-event');
    final fooBar = testComp.fooBar;
    fooBar.fireFoo(123);
    fooBar.fireBarBaz(42);
    fooBar.fireFoo(777);

    final events = testComp.events;
    expect(events.length, 3);
    expect(events.map((e) => e[0]), ['foo', 'barbaz', 'foo']);
    expect(events.map((e) => e[1].detail), [123, 42, 777]);
  });
}
