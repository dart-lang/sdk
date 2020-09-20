// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests method calls (typed and dynamic) on various forms of JS objects.

@JS()
library js_parameters_test;

import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
external void eval(String code);

@JS()
class Foo {
  external Foo();
  external dynamic method(int x);
}

@JS()
external Foo makeFooLiteral();

@JS()
external Foo makeFooObjectCreate();

main() {
  // These examples from based on benchmarks-internal/js
  eval(r'''
self.Foo = function Foo() {}
self.Foo.prototype.method = function(x) { return x + 1; }

self.makeFooLiteral = function() {
  return {
    method: function(x) { return x + 1; }
  }
}

// Objects created in this way have no prototype.
self.makeFooObjectCreate = function() {
  var o = Object.create(null);
  o.method = function(x) { return x + 1; }
  return o;
}
''');

  var foo = Foo();
  Expect.equals(2, foo.method(1));

  foo = makeFooLiteral();
  Expect.equals(2, foo.method(1));

  foo = makeFooObjectCreate();
  Expect.equals(2, foo.method(1));

  dynamic dynamicFoo = Foo();
  Expect.equals(2, dynamicFoo.method(1));

  dynamicFoo = makeFooLiteral();
  Expect.equals(2, dynamicFoo.method(1));

  dynamicFoo = makeFooObjectCreate();
  Expect.equals(2, dynamicFoo.method(1));
}
