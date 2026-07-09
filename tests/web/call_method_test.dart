// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// WARNING
///
/// Not all of the expectations in this test match the language specification.
///
/// This is part of a set of tests covering "callable objects". Please consider
/// them all together when making changes:
///
/// ```
/// tests/web/call_field_test.dart
/// tests/web/call_getter_test.dart
/// tests/web/call_method_test.dart
/// ```
///
/// This test was created with expectations that match the current behavior to
/// make it more clear when something changes and when the results in the web
/// compilers differ.
///
/// If your change causes an expectation to fail you should decide if the
/// new result is desirable and update the expectation accordingly.

import 'package:expect/expect.dart';

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
dynamic confuse(dynamic x) => x;

class C {
  int call(String s) => s.length;
}

extension on A {
  int call(String s) => s.length;
}

class A {}

extension type ExtType(B _) {
  int call(String s) => s.length;
}

class B {}

void main() {
  var c = C();
  Expect.equals(5, c.call('Cello'));
  Expect.equals(5, (c.call)('Cello'));
  Expect.equals(5, c('Cello'));

  var d = confuse(C());
  Expect.equals(5, d.call('Fosse'));
  Expect.equals(5, (d.call)('Fosse'));
  Expect.equals(5, d('Fosse'));

  var a = A();
  Expect.equals(5, a.call('Cello'));
  Expect.equals(5, (a.call)('Cello'));
  Expect.equals(5, a('Cello'));

  d = confuse(A());
  Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  Expect.throwsNoSuchMethodError(() => (d.call)('Fosse'));
  Expect.throwsNoSuchMethodError(() => d('Fosse'));

  var b = ExtType(B());
  Expect.equals(5, b.call('Cello'));
  Expect.equals(5, (b.call)('Cello'));
  Expect.equals(5, b('Cello'));

  d = confuse(ExtType(B()));
  Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  Expect.throwsNoSuchMethodError(() => (d.call)('Fosse'));
  Expect.throwsNoSuchMethodError(() => d('Fosse'));
}
