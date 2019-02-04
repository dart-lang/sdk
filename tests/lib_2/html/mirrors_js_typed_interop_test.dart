// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// dartdevcOptions=--emit-metadata

// TODO(jmesserly): delete this test file once `dart:mirrors` is fully diabled
// in dart4web compilers.

@JS()
library tests.html.mirrors_js_typed_interop_test;

import 'dart:mirrors';
import 'dart:html';

import 'package:js/js.dart';
import 'package:expect/minitest.dart';

_injectJs() {
  document.body.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
  window.foo = {
    x: 3,
    z: 100,
    multiplyBy2: function(arg) { return arg * 2; },
  };
""");
}

@JS()
external Foo get foo;

@JS()
class Foo {
  external int get x;
  external set x(v);
  external num multiplyBy2(num y);
}

main() {
  _injectJs();

  test('dynamic dispatch', () {
    var f = foo;
    expect(f.x, 3);
    // JsInterop methods are not accessible using reflection.
    expect(() => reflect(f).setField(#x, 123), throws);
    expect(f.x, 3);
  });

  test('generic function metadata', () {
    // TODO(jmesserly): this test is not related to JS interop, but this is the
    // only test we have for DDC's deprecated --emit-metadata flag.
    expect(testGenericFunctionMetadata(42), int);
    var testFn = testGenericFunctionMetadata;
    expect(reflect(testFn).type.reflectedType, testFn.runtimeType); //# 01: ok
  });
}

Type testGenericFunctionMetadata<T>(T _) => T;
