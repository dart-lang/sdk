// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html' as dom;

import 'package:expect/minitest.dart';

// Not defined in dom.Window.
foo(x) => x;

class Unused {
  foo(x) => 'not $x';
}

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

main() {
  var things = <dynamic>[new Unused(), dom.window];

  test('windowNonMethod', () {
    var win = things[inscrutable(1)];
    final message = foo("Hello World");
    expect(() => win.foo(message), throwsNoSuchMethodError);
  });

  test('foo', () {
    var win = things[inscrutable(0)];
    String x = win.foo('bar');
    expect(x, 'not bar');
  });

  // Use dom.window directly in case the compiler does type inference.
  test('windowNonMethod2', () {
    final message = foo("Hello World");
    expect(() => (dom.window as dynamic).foo(message), throwsNoSuchMethodError);
  });
}
