// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: f:deps=[B],direct,explicit=[f.T*],needsArgs,needsInst=[<B.S*>]*/
bool f<T>(T a) => a is T;

typedef bool F<R>(R a);

/*spec.class: B:explicit=[bool* Function(B.S*)*],indirect,needsArgs*/
/*prod.class: B:indirect,needsArgs*/
class B<S> {
  F<S> c;

  B() : c = f;
}

main() {
  new B();
}
