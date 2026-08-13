// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async" show FutureOr;
import "dart:mirrors";

import "package:expect/expect.dart";

typedef void FooFunction(int a, double b);
typedef Rec = (int,);
typedef Void = void;

void main() {
  // `void`, `dynamic` and `Never` are not classes.
  Expect.throwsArgumentError(() => reflectClass(dynamic));
  Expect.throwsArgumentError(() => reflectClass(Void));
  Expect.throwsArgumentError(() => reflectClass(Never));
  // Cannot reflect a function type.
  Expect.throwsArgumentError(() => reflectClass(FooFunction));

  // Can reflect on [FutureOr], a "class" with no declarations other than
  // a type variable, and `Object` as superclass.
  reflectClass(FutureOr<int>);

  // (Record types are completely unsupported and crashes the VM.)
}
