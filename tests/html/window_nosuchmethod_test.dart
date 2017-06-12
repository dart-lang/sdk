// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library WindowNSMETest;

import "package:expect/expect.dart";
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html' as dom;

// Not defined in dom.Window.
foo(x) => x;

class Unused {
  foo(x) => 'not $x';
}

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

main() {
  useHtmlConfiguration();
  var things = [new Unused(), dom.window];

  test('windowNonMethod', () {
    var win = things[inscrutable(1)];
    final message = foo("Hello World");
    try {
      String x = win.foo(message);
      expect(false, isTrue, reason: 'Should not reach here: $x');
    } on NoSuchMethodError catch (e) {
      // Expected exception.
    } on Exception catch (e) {
      expect(false, isTrue, reason: 'Wrong exception: $e');
    }
  });

  test('foo', () {
    var win = things[inscrutable(0)];
    String x = win.foo('bar');
    expect(x, 'not bar');
  });

  // Use dom.window directly in case the compiler does type inference.
  test('windowNonMethod2', () {
    final message = foo("Hello World");
    try {
      String x = dom.window.foo(message);
      expect(false, isTrue, reason: 'Should not reach here: $x');
    } on NoSuchMethodError catch (e) {
      // Expected exception.
    } on Exception catch (e) {
      expect(false, isTrue, reason: 'Wrong exception: $e');
    }
  });
}
