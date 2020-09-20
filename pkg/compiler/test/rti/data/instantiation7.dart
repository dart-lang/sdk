// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.member: f1:deps=[method],direct,explicit=[f1.T*],needsArgs,needsInst=[<method.X*>]*/
/*prod.member: f1:deps=[method]*/
int f1<T>(T a, T b, T c) => null;

/*spec.member: f2:deps=[method],direct,explicit=[f2.S*,f2.T*],needsArgs,needsInst=[<method.X*,method.Y*>]*/
/*prod.member: f2:deps=[method]*/
int f2<T, S>(T a, S b, S c) => null;

/*spec.member: f3:deps=[method],direct,explicit=[f3.S*,f3.T*,f3.U*],needsArgs,needsInst=[<method.X*,method.Y*,method.Z*>]*/
/*prod.member: f3:deps=[method]*/
int f3<T, S, U>(T a, S b, U c) => null;

typedef int F1<R>(R a, R b, R c);
typedef int F2<R, P>(R a, P b, P c);
typedef int F3<R, P, Q>(R a, P b, Q c);

/*spec.member: method:indirect,needsArgs*/
method<X, Y, Z>() {
  F1<X> c1;
  F2<X, Y> c2;
  F3<X, Y, Z> c3;

  return () {
    c1 = f1;
    c2 = f2;
    c3 = f3;
    return c1 ?? c2 ?? c3;
  };
}

main() {
  method();
}
