// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

@CustomTag('my-element')
class MyElement extends PolymerElement {
  MyElement.created() : super.created();

  @published double volume;
  @published int factor;
  @published bool crankIt;
  @published String msg;
  @published DateTime time;
  @published Object json;
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('attributes were deserialized', () {
    MyElement elem = querySelector('my-element');
    final msg = 'property should match attribute.';
    expect(elem.volume, 11.0, reason: '"volume" should match attribute');
    expect(elem.factor, 3, reason: '"factor" should match attribute');
    expect(elem.crankIt, true, reason: '"crankIt" should match attribute');
    expect(elem.msg, "Yo!", reason: '"msg" should match attribute');
    expect(elem.time, DateTime.parse('2013-08-08T18:34Z'),
        reason: '"time" should match attribute');
    expect(elem.json, {'here': 'is', 'some': 'json', 'x': 123},
        reason: '"json" should match attribute');

    var text = elem.shadowRoot.text;
    // Collapse adjacent whitespace like a browser would:
    text = text.replaceAll('\n', ' ').replaceAll(new RegExp(r'\s+'), ' ');

    // Note: using "${33.0}" because the toString differs in JS vs Dart VM.
    expect(text, " Yo! The volume is ${33.0} !! The time is "
        "2013-08-08 18:34:00.000Z and here's some JSON: "
        "{here: is, some: json, x: 123} ",
        reason: 'text should match expected HTML template');
  });
});
