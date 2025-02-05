// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

typedef void FooFunction(int a, double b);
typedef Rec = (int,);
typedef Void = void;

main() {
  Expect.throwsArgumentError(() => reflectClass(dynamic));
  Expect.throwsArgumentError(() => reflectClass(Void));
  Expect.throwsArgumentError(() => reflectClass(Never));
  Expect.throwsArgumentError(() => reflectClass(FooFunction));
  Expect.throwsArgumentError(() => reflectClass(Rec));
}
