// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

// Test ported from:
// https://github.com/Polymer/polymer-dev/blob/0.3.4/test/html/computedProperties.html
@CustomTag('x-foo')
class XFoo extends PolymerElement {
  XFoo.created(): super.created();

  // Left like this to illustrate the old-style @published pattern next to the
  // new style below.
  @published int count;

  @published
  String get foo => readValue(#foo);
  set foo(String v) => writeValue(#foo, v);

  @published
  String get bar => readValue(#bar);
  set bar(String v) => writeValue(#bar, v);

  @ComputedProperty('repeat(fooBar, count)')
  String get fooBarCounted => readValue(#fooBarCounted);

  @ComputedProperty('foo + "-" + bar')
  String get fooBar => readValue(#fooBar);

  @ComputedProperty('this.foo')
  String get foo2 => readValue(#foo2);
  set foo2(v) => writeValue(#foo2, v);

  @ComputedProperty('bar + ""')
  String get bar2 => readValue(#bar2);
  set bar2(v) => writeValue(#bar2, v);

  repeat(String s, int count) {
    var sb = new StringBuffer();
    for (var i = 0; i < count; i++) {
      if (i > 0) sb.write(' ');
      sb.write(s);
      sb.write('($i)');
    }
    return sb.toString();
  }
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('computed properties basic', () {
    var xFoo = querySelector('x-foo');
    var html = xFoo.shadowRoot.innerHtml;
    expect(html, 'mee-too:mee-too(0) mee-too(1) mee-too(2)');
    expect(xFoo.fooBar, 'mee-too');
  });

  // Dart note: the following tests were not in the original JS test.
  test('computed properties can be updated', () {
    var xFoo = querySelector('x-foo');
    expect(xFoo.foo, 'mee');
    expect(xFoo.foo2, 'mee');
    xFoo.foo2 = 'hi';
    expect(xFoo.foo, 'hi');
    expect(xFoo.foo2, 'hi');
  });

  test('only assignable expressions can be updated', () {
    var xFoo = querySelector('x-foo');
    expect(xFoo.bar, 'too');
    expect(xFoo.bar2, 'too');
    xFoo.bar2 = 'hi';
    expect(xFoo.bar, 'too');
    expect(xFoo.bar2, 'too');
  });
});
