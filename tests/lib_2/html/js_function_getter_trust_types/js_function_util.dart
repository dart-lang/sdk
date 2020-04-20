// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--trust-type-annotations
@JS()
library js_function_getter_trust_types_test;

import 'dart:html';

import 'package:js/js.dart';

injectJs() {
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
