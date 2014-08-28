// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.event_binding_release_handler_test;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:template_binding/template_binding.dart';

@CustomTag('x-foo')
class XFoo extends PolymerElement {
  @PublishedProperty(reflect: true)
  int count = 1;

  XFoo.created() : super.created();

  increment() { ++count; }
}

main() {
  // Do not run the test in the zone so the future does not trigger a
  // dirtyCheck. We want to verify that event bindings trigger dirty checks on
  // their own.
  initPolymer();

  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('event handlers can be released', () {
    XFoo element = querySelector('x-foo');
    expect(element, isNotNull);
    ButtonElement button = element.shadowRoot.querySelector('button');
    expect(button, isNotNull);

    button.click();
    return new Future(() {}).then((_) {
      expect(element.shadowRoot.querySelector('p').text, 'Count: 2');
      // Remove and detach the element so the binding is invalidated.
      element.remove();
      element.detached();
    }).then((_) => new Future(() {})).then((_) {
      // Clicks should no longer affect the elements count.
      button.click();
      // TODO(jakemac): This is flaky so its commented out, (the rest of the
      // test is not flaky). Figure out how to make this not flaky.
//      expect(element.count, 2);
    });
  });
}
