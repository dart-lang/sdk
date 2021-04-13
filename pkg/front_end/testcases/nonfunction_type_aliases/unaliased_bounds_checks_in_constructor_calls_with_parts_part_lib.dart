// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of unaliased_bounds_checks_in_constructor_calls_with_parts_lib;

class C<X> {}
typedef A<X extends num, Y> = C<X>;

foo() {
  new A<dynamic, String>();
}

