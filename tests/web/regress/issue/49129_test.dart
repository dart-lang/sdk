// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This is a regression test for a bug in how tear-offs of JSinterop top-level
/// methods were generated.
///
/// A `.` in the JS-name of a interop method means that the method is accessible
/// via a path of selectors, not that the `.` was meant to be part of the
/// selector name.
///
/// See: https://github.com/dart-lang/sdk/issues/49129

import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS('a.Foo.c.d.plus')
external plus1(arg1);

@JS('a.Foo.c.d')
class Foo {
  // Note: dots are not allowed in static class members, so the issue didn't
  // arise in this case.
  @JS('plus')
  external static plus1(arg);
}

@JS()
external eval(String s);

main() {
  eval('self.a = {Foo: {c: {d: {plus: function(a, b) { return a + 1; }}}}};');

  // Tear-off for top-level with dotted names.
  Expect.equals(2, (plus1)(1));

  // Can also be accessed as a static method (with no dots).
  Expect.equals(3, (Foo.plus1)(2));
}
