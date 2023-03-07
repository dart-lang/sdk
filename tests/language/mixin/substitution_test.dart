// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

// Test that mixins don't interfere with type variable substitution.

import '../dynamic_type_helper.dart';

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
  new C<String>('');
  dynamic value = 0;
  checkDynamicTypeError(() => new C<String>(value));
}
