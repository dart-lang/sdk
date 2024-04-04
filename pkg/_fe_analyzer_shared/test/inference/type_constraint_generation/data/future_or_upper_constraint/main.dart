// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test case exercises the code path in type constraint generation where a
// type is constrained by a `FutureOr<T>` from above for some type `T`.

import 'dart:async';

Future<T> inferable1<T>(T t) => new Future<T>.value(t);
context1(FutureOr<num> futureOrNum) {}

FutureOr<T> inferable2<T>(T t) => t;
context2(Object x) {}

main() {
  context1(inferable1 /*T <: num,T :> int*/ (0));
  context2(inferable2 /*T <: Object,T :> bool*/ (false));
}
