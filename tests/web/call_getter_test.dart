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

const dart2js = const bool.fromEnvironment('dart.library._dart2js_only');
const ddc = const bool.fromEnvironment('dart.library._ddc_only');

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
dynamic confuse(dynamic x) => x;

class C {
  int Function(String s) get call =>
      (s) => s.length;
}

class C2 {
  Function get call =>
      (s) => s.length;
}

extension on A {
  int Function(String s) get call =>
      (s) => s.length;
}

class A {}

extension on A2 {
  Function get call =>
      (s) => s.length;
}

class A2 {}

extension type ExtType(B _) {
  int Function(String s) get call =>
      (s) => s.length;
}

extension type ExtType2(B _) {
  Function get call =>
      (s) => s.length;
}

class B {}

final expectJSCompilersOnlyMessage =
    'Test only expects to run on dart2js and ddc configurations.';

void main() {
  var c = C();
  Expect.equals(5, c.call('Cello'));
  Expect.equals(5, (c.call)('Cello'));

  var d = confuse(C());
  if (dart2js) {
    Expect.equals(5, d.call('Fosse'));
  } else if (ddc) {
    Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  } else {
    Expect.fail(expectJSCompilersOnlyMessage);
  }
  Expect.equals(5, (d.call)('Fosse'));
  if (dart2js) {
    Expect.equals(5, d('Fosse'));
  } else if (ddc) {
    Expect.throwsNoSuchMethodError(() => d('Fosse'));
  } else {
    Expect.fail(expectJSCompilersOnlyMessage);
  }

  var c2 = C2();
  if (dart2js) {
    Expect.equals(5, c2.call('Cello'));
  } else {
    Expect.throwsNoSuchMethodError(() => c2.call('Cello'));
  }
  Expect.equals(5, (c2.call)('Cello'));

  d = confuse(C2());
  if (dart2js) {
    Expect.equals(5, d.call('Fosse'));
  } else if (ddc) {
    Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  } else {
    Expect.fail(expectJSCompilersOnlyMessage);
  }
  Expect.equals(5, (d.call)('Fosse'));
  if (dart2js) {
    Expect.equals(5, d('Fosse'));
  } else if (ddc) {
    Expect.throwsNoSuchMethodError(() => d('Fosse'));
  } else {
    Expect.fail(expectJSCompilersOnlyMessage);
  }

  var a = A();
  Expect.equals(5, a.call('Cello'));
  Expect.equals(5, (a.call)('Cello'));

  d = confuse(A());
  Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  Expect.throwsNoSuchMethodError(() => (d.call)('Fosse'));
  Expect.throwsNoSuchMethodError(() => d('Fosse'));

  var a2 = A2();
  Expect.equals(5, a2.call('Cello'));
  Expect.equals(5, (a2.call)('Cello'));

  d = confuse(A2());
  Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  Expect.throwsNoSuchMethodError(() => (d.call)('Fosse'));
  Expect.throwsNoSuchMethodError(() => d('Fosse'));

  var e = ExtType(B());
  Expect.equals(5, e.call('Cello'));
  Expect.equals(5, (e.call)('Cello'));

  d = confuse(ExtType(B()));
  Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  Expect.throwsNoSuchMethodError(() => (d.call)('Fosse'));
  Expect.throwsNoSuchMethodError(() => d('Fosse'));

  var e2 = ExtType2(B());
  Expect.equals(5, e2.call('Cello'));
  Expect.equals(5, (e2.call)('Cello'));

  d = confuse(ExtType2(B()));
  Expect.throwsNoSuchMethodError(() => d.call('Fosse'));
  Expect.throwsNoSuchMethodError(() => (d.call)('Fosse'));
  Expect.throwsNoSuchMethodError(() => d('Fosse'));
}
