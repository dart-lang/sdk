// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that mixins don't interfere with type variable substitution.

import 'dynamic_type_helper.dart';

class B<T> {
  B(T x);
}

class M {}

class A<T> extends B<T> with M {
  A(T x) : super(x); // This line must be warning free.
}

class C<T> = B<T> with M;

main() {
  new A(null);
  new C<String>(''); //# 01: ok
  checkDynamicTypeError(() => new C<String>(0)); //# 02: compile-time error
}
