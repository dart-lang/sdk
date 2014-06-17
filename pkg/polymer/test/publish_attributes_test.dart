// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

// Dart note: unlike JS, you can't publish something that doesn't
// have a corresponding field because we can't dynamically add properties.
// So we define XFoo and XBar types here.
@CustomTag('x-foo')
class XFoo extends PolymerElement {
  XFoo.created() : super.created();

  @observable var Foo;
  @observable var baz;
}

@CustomTag('x-bar')
class XBar extends XFoo {
  XBar.created() : super.created();

  @observable var Bar;
}

@CustomTag('x-zot')
class XZot extends XBar {
  XZot.created() : super.created();

  @published int zot = 3;
}

@CustomTag('x-squid')
class XSquid extends XZot {
  XSquid.created() : super.created();

  @published int baz = 13;
  @published int zot = 3;
  @published int squid = 7;
}

// Test inherited "attriubtes"
class XBaz extends PolymerElement {
  XBaz.created() : super.created();
  @observable int qux = 13;
}

@CustomTag('x-qux')
class XQux extends XBaz {
  XQux.created() : super.created();
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('published properties', () {
    published(tag) => (new Element.tag(tag) as PolymerElement)
        .element.publishedProperties;

    expect(published('x-foo'), ['Foo', 'baz']);
    expect(published('x-bar'), ['Foo', 'baz', 'Bar']);
    expect(published('x-zot'), ['Foo', 'baz', 'Bar', 'zot']);
    expect(published('x-squid'), ['Foo', 'baz', 'Bar', 'zot', 'squid']);
    expect(published('x-qux'), ['qux']);
  });
});
