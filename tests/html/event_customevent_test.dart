// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library EventCustomEventTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';
import 'dart:js' as js;

class DartPayloadData {
  final dartValue;

  DartPayloadData(this.dartValue);
}

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

    var ev = new CustomEvent('foo',
        canBubble: false, cancelable: false, detail: {'type': 'detail'});
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

  test('custom events to JS', () {
    expect(js.context['gotDartEvent'], isNull);
    var scriptContents = '''
      window.addEventListener('dart_custom_event', function(e) {
        if (e.detail == 'dart_message') {
          e.preventDefault();
          window.gotDartEvent = true;
        }
        window.console.log('here' + e.detail);
      }, false);''';

    document.body.append(new ScriptElement()..text = scriptContents);

    var event = new CustomEvent('dart_custom_event', detail: 'dart_message');
    window.dispatchEvent(event);
    expect(js.context['gotDartEvent'], isTrue);
  });

  test('custom data to Dart', () {
    var data = new DartPayloadData(666);
    var event = new CustomEvent('dart_custom_data_event', detail: data);

    var future = window.on['dart_custom_data_event'].first.then((_) {
      expect(event.detail.dartValue, 666);
    });

    document.body.dispatchEvent(event);
    return future;
  });
}
