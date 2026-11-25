// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/64788:
// Passing an explicit `null` to a nullable optional parameter whose overrides
// have different default values must bind `null`, not the default value.

import 'package:expect/expect.dart';

class A {
  int? f([int? x = 1]) => x;
  int? g({int? x = 1}) => x;
  int? fNullDefault([int? x]) => x;
  bool? fBool([bool? x = true]) => x;
  String? fStr([String? x = 'a']) => x;
  Object? fObj([Object? x = 1]) => x;
}

class B extends A {
  @override
  int? f([int? x = 2]) => x;
  @override
  int? g({int? x = 2}) => x;
  @override
  int? fNullDefault([int? x = 2]) => x;
  @override
  bool? fBool([bool? x = false]) => x;
  @override
  String? fStr([String? x = 'b']) => x;
  @override
  Object? fObj([Object? x = 'b']) => x;
}

void main() {
  final instances = <A>[A(), B()];
  for (var i = 0; i < instances.length; i++) {
    final a = instances[i];
    final isA = i == 0;

    // Omitted arguments use each override's default.
    Expect.equals(isA ? 1 : 2, a.f());
    Expect.equals(isA ? 1 : 2, a.g());
    Expect.equals(isA ? null : 2, a.fNullDefault());
    Expect.equals(isA ? true : false, a.fBool());
    Expect.equals(isA ? 'a' : 'b', a.fStr());
    Expect.equals(isA ? 1 : 'b', a.fObj());

    // Explicit `null` and zero values must not be replaced by defaults.
    for (final x in <int?>[null, 0, 3]) {
      Expect.equals(x, a.f(x));
      Expect.equals(x, a.g(x: x));
      Expect.equals(x, a.fNullDefault(x));
      Expect.equals(x, (a as dynamic).f(x));
      Expect.equals(x, (a as dynamic).g(x: x));
      final tearOff = a.f;
      Expect.equals(x, tearOff(x));
    }
    for (final x in <bool?>[null, false, true]) {
      Expect.equals(x, a.fBool(x));
    }
    for (final x in <String?>[null, '', 'x']) {
      Expect.equals(x, a.fStr(x));
    }
    for (final x in <Object?>[null, 0, '']) {
      Expect.equals(x, a.fObj(x));
    }
  }
}
