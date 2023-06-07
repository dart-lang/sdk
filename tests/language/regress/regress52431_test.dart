// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for https://github.com/dart-lang/sdk/issues/52431.
///
/// Type parameters can shadow the core Object type. This was causing a crash
/// in DDC compiled code because it was shadowing the native JavaScript Object.

import 'package:expect/expect.dart';

import 'dart:core' as core;

// Applying a mixin with a class cycle causes a crash when trying to walk up the
// prototype chain using `Object.getPrototypeOf()`.
class A<Object> extends B with C<A> {
  get extractType => Object;

  // Calling super here caused a crash when trying to walk up the prototype
  // chain using `Object.getPrototypeOf()`.
  A() : super();
}

class B {
  final core.int bar;
  B() : bar = 0;
}

mixin C<T> {}

void main() {
  var a = A();
  Expect.notEquals(core.Object, a.extractType);

  a = A<core.Object>();
  Expect.equals(core.Object, a.extractType);
}
