// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// There was a bug in the Kernel mixin transformation: it copied factory
// constructors from the mixin into the mixin application class.  This could be
// observed as an unbound type parameter which led to a crash.

class State<T> {}

class A {}

abstract class Mixin<T> {
  factory Mixin._() => null;
}

class AState extends State<A> {}

class AStateImpl extends AState with Mixin {}

void main() {
  new AStateImpl();
}
