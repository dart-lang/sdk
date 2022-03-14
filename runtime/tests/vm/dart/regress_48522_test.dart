// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/48522.
// Test that FutureOr<T?> = FutureOr<T?>? <: Future<T?>?.

import 'dart:async';

import 'package:expect/expect.dart';

Future<String?>? foo() {
  return null;
}

FutureOr<String?>? bar() {
  return null;
}

FutureOr<String?> baz() {
  return null;
}

typedef F = FutureOr<String?> Function();
typedef G = FutureOr<String?>? Function();

void main() {
  // Check Future<T?>? <: FutureOr<T?>?.
  print(foo.runtimeType);
  Expect.isTrue(foo is G);
  (foo as dynamic) as G; // Should not throw.

  final G v1 = foo;
  print(v1.runtimeType);
  Expect.isTrue(v1 is G);
  (v1 as dynamic) as G; // Should not throw.

  // Check Future<T?>? <: FutureOr<T?>.
  print(foo.runtimeType);
  Expect.isTrue(foo is F);
  (foo as dynamic) as F; // Should not throw.

  final F v2 = foo;
  print(v2.runtimeType);
  Expect.isTrue(v2 is F);
  (v2 as dynamic) as F; // Should not throw.

  // Check FutureOr<T?> = FutureOr<T?>?.
  print(bar.runtimeType);
  Expect.isTrue(bar is F);
  (bar as dynamic) as F; // Should not throw.
  print(baz.runtimeType);
  Expect.isTrue(baz is G);
  (baz as dynamic) as G; // Should not throw.
}
