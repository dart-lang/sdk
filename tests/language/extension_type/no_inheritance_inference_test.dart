// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/static_type_helper.dart';

class A {
  A get x => this;
  set x(A _) {}
  A method(A value) => value;
}

const Object? d = _D();

class _D {
  const _D();
  // Can only be called if receiver has type `_D` or `dynamic`,
  // and nothing has type `_D`.
  void expectDynamicType() {}
}

extension type E(A _) {
  A get x2 => _;
  set x2(A _) {}
  A method2(A value) => value;
}

// Extension type declarations with missing types *do not* inherit from
// superinterface members.
extension type SE(A _) implements A, E {
  get x => d;
  set x(_) {}
  method(_) {}
  get x2 => d;
  set x2(_) {}
  method2(_) {}
}

void main() {
  var se = SE(A());
  se.x.expectDynamicType();
  se.x = expr(d)..expectDynamicType();
  se.method.expectStaticType<Exactly<dynamic Function(dynamic)>>();
  se.x2.expectDynamicType();
  se.x2 = expr(d)..expectDynamicType();
  se.method2.expectStaticType<Exactly<dynamic Function(dynamic)>>();
}

/// Expression with type [T].
///
/// Inferred to have same type as context type if no type parameter provided.
T expr<T>([Object? value]) => value as T;
