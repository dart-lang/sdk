// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec:nnbd-off|prod:nnbd-off.member: f:deps=[B],direct,explicit=[f.T],needsArgs,needsInst=[<B.S>]*/
/*spec:nnbd-sdk|prod:nnbd-sdk.member: f:deps=[B],direct,explicit=[f.T*],needsArgs,needsInst=[<B.S*>]*/
bool f<T>(T a) => a is T;

typedef bool F<R>(R a);

/*spec:nnbd-off.class: B:direct,explicit=[bool Function(B.S)],needsArgs*/
/*prod:nnbd-off|prod:nnbd-sdk.class: B:indirect,needsArgs*/
/*spec:nnbd-sdk.class: B:direct,explicit=[bool* Function(B.S*)*],needsArgs*/
class B<S> {
  F<S> c;

  method() {
    return () {
      c = f;
    };
  }
}

main() {
  new B().method();
}
