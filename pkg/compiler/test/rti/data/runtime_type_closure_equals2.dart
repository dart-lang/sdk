// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*spec:nnbd-off|prod:nnbd-off.class: Class:*/
class Class<T> {
  /*spec:nnbd-off|prod:nnbd-off.member: Class.:*/
  Class();
}

/*spec:nnbd-off|prod:nnbd-off.member: main:*/
main() {
  /*needsArgs,needsSignature*/
  T local1a<T>() => null;

  /*needsArgs,needsSignature*/
  T local1b<T>() => null;

  /*spec:nnbd-off.direct,explicit=[local2.T],needsArgs,needsSignature*/
  /*prod:nnbd-off|prod:nnbd-sdk.needsArgs,needsSignature*/
  /*spec:nnbd-sdk.direct,explicit=[local2.T*],needsArgs,needsSignature*/ T
      local2<T>(T t, String s) => t;

  Expect.isTrue(local1a.runtimeType == local1b.runtimeType);
  Expect.isFalse(local1a.runtimeType == local2.runtimeType);
  new Class();
}
