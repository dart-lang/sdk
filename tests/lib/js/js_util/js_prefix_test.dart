// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the functionality of the JS$ prefix for escaping keywords in JS names.
// Currently only implemented in dart2js, expected to fail in ddc.

@JS()
library js_prefix_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

@JS()
@anonymous
class ExampleTypedLiteral {
  external factory ExampleTypedLiteral({JS$_c, JS$class});

  external get JS$_c;
  external set JS$_c(v);
  // Identical to JS$_c but only accessible within the library.
  external get _c;
  external get JS$class;
  external set JS$class(v);
}

main() {
  test('hasProperty', () {
    var literal = new ExampleTypedLiteral(JS$_c: null, JS$class: true);
    expect(js_util.hasProperty(literal, '_c'), isTrue);
    expect(literal.JS$_c, isNull);
    expect(js_util.hasProperty(literal, 'class'), isTrue);
    // JS$_c escapes to _c so the property JS$_c will not exist on the object.
    expect(js_util.hasProperty(literal, r'JS$_c'), isFalse);
    expect(js_util.hasProperty(literal, r'JS$class'), isFalse);
    expect(literal.JS$class, isTrue);

    literal = new ExampleTypedLiteral();
    expect(js_util.hasProperty(literal, '_c'), isFalse);
    expect(js_util.hasProperty(literal, 'class'), isFalse);

    literal = new ExampleTypedLiteral(JS$_c: 74);
    expect(js_util.hasProperty(literal, '_c'), isTrue);
    expect(literal.JS$_c, equals(74));
  });

  test('getProperty', () {
    var literal = new ExampleTypedLiteral(JS$_c: 7, JS$class: true);
    expect(js_util.getProperty(literal, '_c'), equals(7));
    expect(literal.JS$_c, equals(7));
    expect(js_util.getProperty(literal, 'class'), isTrue);
    expect(js_util.getProperty(literal, r'JS$_c'), isNull);
    expect(js_util.getProperty(literal, r'JS$class'), isNull);
  });

  test('setProperty', () {
    var literal = new ExampleTypedLiteral();
    literal.JS$class = 42;
    expect(literal.JS$class, equals(42));
    js_util.setProperty(literal, 'class', 100);
    expect(literal.JS$class, equals(100));
  });
}
