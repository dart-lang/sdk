// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that generic methods with unused parameters aren't treated as
// non-generic methods, but can be specialized as such.

library generic_methods_unused_parameter_test;

import "package:expect/expect.dart";

typedef Fun = int Function();
typedef FunReq = int Function(int);
typedef FunOpt = int Function([int]);
typedef FunReqOpt = int Function(int, [int]);
typedef FunNam = int Function({int p});
typedef FunReqNam = int Function(int, {int p});

typedef FunTyp = int Function<T>();
typedef FunTypReq = int Function<T>(int);
typedef FunTypOpt = int Function<T>([int]);
typedef FunTypReqOpt = int Function<T>(int, [int]);
typedef FunTypNam = int Function<T>({int p});
typedef FunTypReqNam = int Function<T>(int, {int p});

int fun() {}
int funReq(int x) => x;
int funOpt([int y]) => y ?? 42;
int funReqOpt(int x, [int y]) => x;
int funNam({int p}) => p ?? 42;
int funReqNam(int x, {int p}) => x;

int funTyp<T>() {}
int funTypReq<T>(int x) => x;
int funTypOpt<T>([int y]) => y ?? 42;
int funTypReqOpt<T>(int x, [int y]) => x;
int funTypNam<T>({int p}) => p ?? 42;
int funTypReqNam<T>(int x, {int p}) => x;

main() {
  Fun varFun = funTyp;
  FunReq varFunReq = funTypReq;
  FunOpt varFunOpt = funTypOpt;
  FunReqOpt varFunReqOpt = funTypReqOpt;
  FunNam varFunNam = funTypNam;
  FunReqNam varFunReqNam = funTypReqNam;

  Expect.isTrue(fun is Fun);
  Expect.isTrue(fun is! FunTyp);
  Expect.isTrue(funTyp is! Fun);
  Expect.isTrue(funTyp is FunTyp);
  Expect.isTrue(varFun is Fun);
  Expect.isTrue(varFun is! FunTyp);

  Expect.isTrue(funReq is FunReq);
  Expect.isTrue(funReq is! FunTypReq);
  Expect.isTrue(funTypReq is! FunReq);
  Expect.isTrue(funTypReq is FunTypReq);
  Expect.isTrue(varFunReq is FunReq);
  Expect.isTrue(varFunReq is! FunTypReq);

  Expect.isTrue(funOpt is FunOpt);
  Expect.isTrue(funOpt is! FunTypOpt);
  Expect.isTrue(funTypOpt is! FunOpt);
  Expect.isTrue(funTypOpt is FunTypOpt);
  Expect.isTrue(varFunOpt is FunOpt);
  Expect.isTrue(varFunOpt is! FunTypOpt);

  Expect.isTrue(funReqOpt is FunReqOpt);
  Expect.isTrue(funReqOpt is! FunTypReqOpt);
  Expect.isTrue(funTypReqOpt is! FunReqOpt);
  Expect.isTrue(funTypReqOpt is FunTypReqOpt);
  Expect.isTrue(varFunReqOpt is FunReqOpt);
  Expect.isTrue(varFunReqOpt is! FunTypReqOpt);

  Expect.isTrue(funNam is FunNam);
  Expect.isTrue(funNam is! FunTypNam);
  Expect.isTrue(funTypNam is! FunNam);
  Expect.isTrue(funTypNam is FunTypNam);
  Expect.isTrue(varFunNam is FunNam);
  Expect.isTrue(varFunNam is! FunTypNam);

  Expect.isTrue(funReqNam is FunReqNam);
  Expect.isTrue(funReqNam is! FunTypReqNam);
  Expect.isTrue(funTypReqNam is! FunReqNam);
  Expect.isTrue(funTypReqNam is FunTypReqNam);
  Expect.isTrue(varFunReqNam is FunReqNam);
  Expect.isTrue(varFunReqNam is! FunTypReqNam);
}
