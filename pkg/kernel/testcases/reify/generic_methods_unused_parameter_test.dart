// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that generic methods with unused parameters aren't treated as
// non-generic methods, but can be specialized as such.

library generic_methods_unused_parameter_test;

import "test_base.dart";

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

  expectTrue(fun is Fun);
  expectTrue(fun is! FunTyp);
  expectTrue(funTyp is! Fun);
  expectTrue(funTyp is FunTyp);
  expectTrue(varFun is Fun);
  expectTrue(varFun is! FunTyp);

  expectTrue(funReq is FunReq);
  expectTrue(funReq is! FunTypReq);
  expectTrue(funTypReq is! FunReq);
  expectTrue(funTypReq is FunTypReq);
  expectTrue(varFunReq is FunReq);
  expectTrue(varFunReq is! FunTypReq);

  expectTrue(funOpt is FunOpt);
  expectTrue(funOpt is! FunTypOpt);
  expectTrue(funTypOpt is! FunOpt);
  expectTrue(funTypOpt is FunTypOpt);
  expectTrue(varFunOpt is FunOpt);
  expectTrue(varFunOpt is! FunTypOpt);

  expectTrue(funReqOpt is FunReqOpt);
  expectTrue(funReqOpt is! FunTypReqOpt);
  expectTrue(funTypReqOpt is! FunReqOpt);
  expectTrue(funTypReqOpt is FunTypReqOpt);
  expectTrue(varFunReqOpt is FunReqOpt);
  expectTrue(varFunReqOpt is! FunTypReqOpt);

  expectTrue(funNam is FunNam);
  expectTrue(funNam is! FunTypNam);
  expectTrue(funTypNam is! FunNam);
  expectTrue(funTypNam is FunTypNam);
  expectTrue(varFunNam is FunNam);
  expectTrue(varFunNam is! FunTypNam);

  expectTrue(funReqNam is FunReqNam);
  expectTrue(funReqNam is! FunTypReqNam);
  expectTrue(funTypReqNam is! FunReqNam);
  expectTrue(funTypReqNam is FunTypReqNam);
  expectTrue(varFunReqNam is FunReqNam);
  expectTrue(varFunReqNam is! FunTypReqNam);
}
