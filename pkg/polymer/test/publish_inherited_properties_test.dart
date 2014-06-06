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
class XFoo extends PolymerElement {
  XFoo.created() : super.created();

  @published var Foo;
}

class XBar extends XFoo {
  XBar.created() : super.created();

  @published var Bar;
}

@CustomTag('x-zot')
class XZot extends XBar {
  XZot.created() : super.created();

  var m;
  @published int zot = 3;
}

// TODO(sigmund): uncomment this part of the test too (see dartbug.com/14559)
// class XWho extends XZot {
//   XWho.created() : super.created();
//
//   @published var zap;
// }

@CustomTag('x-squid')
class XSquid extends XZot {
  XSquid.created() : super.created();

  @published int baz = 13;
  @published int zot = 5;
  @published int squid = 7;
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady.then((_) {
    Polymer.register('x-noscript', XZot);
  }));

  test('published properties', () {
    published(tag) => (new Element.tag(tag) as PolymerElement)
        .element.publishedProperties;

    expect(published('x-zot'), ['Foo', 'Bar', 'zot', 'm']);
    expect(published('x-squid'), ['Foo', 'Bar', 'zot', 'm', 'baz', 'squid']);
    expect(published('x-noscript'), ['Foo', 'Bar', 'zot', 'm']);
    // TODO(sigmund): uncomment, see above
    // expect(published('x-squid'), [#Foo, #Bar, #zot, #zap, #baz, #squid]);
  });
});
