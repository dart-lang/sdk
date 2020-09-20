// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class Class<T> {
  Class();
}

main() {
  /*needsArgs,needsSignature*/
  T local1a<T>() => null;

  /*needsArgs,needsSignature*/
  T local1b<T>() => null;

  /*spec.direct,explicit=[local2.T*],needsArgs,needsSignature*/
  /*prod.needsArgs,needsSignature*/
  T local2<T>(T t, String s) => t;

  Expect.isTrue(local1a.runtimeType == local1b.runtimeType);
  Expect.isFalse(local1a.runtimeType == local2.runtimeType);
  new Class();
}
