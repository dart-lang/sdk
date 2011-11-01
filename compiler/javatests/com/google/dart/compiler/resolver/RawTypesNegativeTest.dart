// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Super<T> {}

interface Sub<S> extends Super<S> factory SubImplementation<S> {
  Sub();
}

class SubImplementation<U> implements Sub<U> {
  SubImplementation() {}
}

class A {
  main() {
    Sub<A, A> s = new Sub();
    Sub<A, A> s2 = new Sub<A>();
    Sub<A, A> s3;
    A<A> s4;
  }
}
