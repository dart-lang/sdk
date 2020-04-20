// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that parameter types types are checked correctly in the face of
// mixin application upon a generic constructor.

import '../dynamic_type_helper.dart';

class A<X> {
  A(X x);
}

class B {}

class C {}

class D<Y> = A<Y> with B, C;

void main() {
  var v = 0;
  checkNoDynamicTypeError(() => new D<int>(v));
  checkDynamicTypeError(() => new D<String>(v));
  //                                        ^
  // [analyzer] STATIC_WARNING.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int' can't be assigned to the parameter type 'String'.
}
