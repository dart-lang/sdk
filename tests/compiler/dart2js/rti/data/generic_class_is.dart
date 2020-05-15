// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:implicit=[A]*/
class A {}

/*spec:nnbd-off|prod:nnbd-off.class: B:direct,explicit=[B.T],needsArgs*/
/*spec:nnbd-sdk|prod:nnbd-sdk.class: B:direct,explicit=[B.T*],needsArgs*/
class B<T> {
  @pragma('dart2js:noInline')
  method(T t) => t is T;
}

main() {
  new B<A>().method(new A());
}
