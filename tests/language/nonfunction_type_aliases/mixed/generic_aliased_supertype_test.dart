// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart = 2.9
// Requirements=nnbd-weak


// Test that a type alias `A3` can be used to specify a superclass.

import 'generic_aliased_supertype_lib.dart';

class B extends A3<B> {}

void f(A<A<A<B>>> a) {}

void main() {
  f(B());
}
