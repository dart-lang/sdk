// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library EventCustomEventTest;

import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  test('custom events', () {
    var provider = new EventStreamProvider<CustomEvent>('foo');
    var el = new DivElement();

    var fired = false;
    provider.forTarget(el).listen((ev) {
      fired = true;
      expect(ev.detail, {'type': 'detail'});
    });

    var ev = new CustomEvent('foo', canBubble: false, cancelable: false,
        detail: {'type': 'detail'});
    el.dispatchEvent(ev);
    expect(fired, isTrue);
  });

  test('custom events from JS', () {
    var scriptContents = '''
      var event = document.createEvent("CustomEvent");
      event.initCustomEvent("js_custom_event", true, true, {type: "detail"});
      window.dispatchEvent(event);
    ''';

    var fired = false;
    window.on['js_custom_event'].listen((ev) {
      fired = true;
      expect(ev.detail, {'type': 'detail'});
    });

    var script = new ScriptElement();
    script.text = scriptContents;
    document.body.append(script);

    expect(fired, isTrue);
  });
}
