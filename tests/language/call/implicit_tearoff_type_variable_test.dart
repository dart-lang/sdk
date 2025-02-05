// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that implicit `.call` tearoff properly occurs when the
// static type of the expression is a type variable whose bound implements
// `.call`.

import 'package:expect/static_type_helper.dart';

class C {
  void call() {}
}

void testTypeVariableExtendsCallableClass<T extends C>(T t) {
  context<void Function()>(t);
}

void testTypeVariablePromotedToCallableClass<T>(T t) {
  if (t is C) {
    context<void Function()>(t);
  }
}

void testTypeVariableExtendsOtherTypeVariable<T extends U, U extends C>(T t) {
  context<void Function()>(t);
}

main() {
  testTypeVariableExtendsCallableClass(C());
  testTypeVariablePromotedToCallableClass(C());
  testTypeVariableExtendsOtherTypeVariable(C());
}
