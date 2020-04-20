// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*strong.class: Class:*/
/*omit.class: Class:*/
class Class<T> {
  /*strong.member: Class.:*/
  /*omit.member: Class.:*/
  Class();
}

/*strong.member: main:*/
/*omit.member: main:*/
main() {
  /*strong.needsArgs,needsSignature*/
  /*omit.needsArgs,needsSignature*/
  T local1a<T>() => null;

  /*strong.needsArgs,needsSignature*/
  /*omit.needsArgs,needsSignature*/
  T local1b<T>() => null;

  /*strong.direct,explicit=[local2.T],needsArgs,needsSignature*/
  /*omit.needsArgs,needsSignature*/
  T local2<T>(T t, String s) => t;

  Expect.isTrue(local1a.runtimeType == local1b.runtimeType);
  Expect.isFalse(local1a.runtimeType == local2.runtimeType);
  new Class();
}
