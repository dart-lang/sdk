// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--trust-type-annotations
@JS()
library js_function_getter_trust_types_test;

import 'dart:html';

import 'package:js/js.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/html_individual_config.dart';

_injectJs() {
  document.body.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
  var bar = { };

  bar.nonFunctionStatic = function() {
    return arguments.length * 2;
  };

  bar.add = function(a, b) {
    return a + b;
  };

  var foo = { 'bar' : bar };
""");
}

typedef int AddFn(int x, int y);

@JS()
class NotAFn {}

@JS()
abstract class Bar {
  external AddFn get add;
  external NotAFn get nonFunctionStatic;
}

@JS()
abstract class Foo {
  external Bar get bar;
}

@JS()
external Foo get foo;

main() {
  _injectJs();

  useHtmlIndividualConfiguration();

  test('static nonFunctionStatic', () {
    expect(() => foo.bar.nonFunctionStatic(), throws);
    expect(() => foo.bar.nonFunctionStatic(0), throws);
    expect(() => foo.bar.nonFunctionStatic(0, 0), throws);
    expect(() => foo.bar.nonFunctionStatic(0, 0, 0, 0, 0, 0), throws);
  });

  test('typedef function', () {
    expect(() => foo.bar.add(4), throws);
    expect(() => foo.bar.add(4, 5, 10), throws);
    expect(foo.bar.add(4, 5), equals(9));
  });
}
