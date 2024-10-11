// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that implicit `.call` tearoff does not occur when the
// static type of the expression is a nullable type variable, or a type variable
// whose bound is nullable.

import 'package:expect/static_type_helper.dart';

class C {
  void call() {}
}

void testTypeVariableExtendsCallableClass<T extends C>(T? t) {
  context<void Function()>(t);
  //                       ^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] Can't tear off method 'call' from a potentially null value.
}

void testTypeVariableExtendsNullableCallableClass<T extends C?>(T t) {
  context<void Function()>(t);
  //                       ^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] Can't tear off method 'call' from a potentially null value.
}

void testTypeVariablePromotedToNullableCallableClass<T>(T t) {
  if (t is C?) {
    context<void Function()>(t);
    //                       ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] Can't tear off method 'call' from a potentially null value.
  }
}

void testTypeVariableExtendsNullableTypeVariable<T extends U?, U extends C>(
    T t) {
  context<void Function()>(t);
  //                       ^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] Can't tear off method 'call' from a potentially null value.
}

main() {}
