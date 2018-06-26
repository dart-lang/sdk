// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*kernel.class: Class:needsArgs*/
/*strong.class: Class:*/
/*omit.class: Class:*/
class Class<T> {
  /*kernel.element: Class.:needsSignature*/
  /*strong.element: Class.:*/
  /*omit.element: Class.:*/
  Class();
}

/*kernel.element: main:needsSignature*/
/*strong.element: main:*/
/*omit.element: main:*/
main() {
  /*kernel.needsSignature*/
  /*strong.needsArgs,needsSignature*/
  /*omit.needsArgs,needsSignature*/
  T local1a<T>() => null;

  /*kernel.needsSignature*/
  /*strong.needsArgs,needsSignature*/
  /*omit.needsArgs,needsSignature*/
  T local1b<T>() => null;

  /*kernel.needsSignature*/
  /*strong.direct,explicit=[local2.T],needsArgs,needsSignature*/
  /*omit.needsArgs,needsSignature*/
  T local2<T>(T t, String s) => t;

  Expect.isTrue(local1a.runtimeType == local1b.runtimeType);
  Expect.isFalse(local1a.runtimeType == local2.runtimeType);
  new Class();
}
