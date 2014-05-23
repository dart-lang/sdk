// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

// Note: we use @CustomTag to make this type reflectable.
@CustomTag('my-element')
class MyElement extends PolymerElement {
  MyElement.created() : super.created();

  // This is here so that [attributes] can be read via mirrors in polymer
  // expressions (@CustomTag in this class makes the attribute reflectable).
  get attributes => super.attributes;
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('attributes were deserialized', () {
    var elem = querySelector('my-element');

    expect(elem.attributes, {'foo': '123', 'bar': 'hi', 'baz': 'world'},
        reason: 'attributes should be copied to instance');

    var text = elem.shadowRoot.text;
    // Collapse adjacent whitespace like a browser would:
    text = text.replaceAll('\n', ' ').replaceAll(new RegExp(r'\s+'), ' ');

    expect(text, " foo: 123 bar: hi baz: world ",
        reason: 'text should match expected HTML template');
  });
});
