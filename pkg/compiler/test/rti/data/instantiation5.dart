// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec:nnbd-off.member: f:deps=[method],direct,explicit=[f.T],needsArgs,needsInst=[<method.S>]*/
/*prod:nnbd-off|prod:nnbd-sdk.member: f:deps=[method]*/
/*spec:nnbd-sdk.member: f:deps=[method],direct,explicit=[f.T*],needsArgs,needsInst=[<method.S*>]*/
int f<T>(T a) => null;

typedef int F<R>(R a);

/*spec:nnbd-off|spec:nnbd-sdk.member: method:indirect,needsArgs*/
method<S>() {
  F<S> c;

  return () {
    c = f;
    return c;
  };
}

main() {
  method();
}
