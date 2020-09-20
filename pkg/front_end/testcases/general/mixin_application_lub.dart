// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Diagnosticable {}

// Originally the existence of this (unused) class (which has an anonymous mixin
// that matches that of `State<T>`) caused an error in the VM's mixin
// deduplication code. This was due to the inferred type for `var x = a ?? b`
// was the anonymous mixin application that got removed during deduplication.
//
// See https://github.com/flutter/flutter/issues/55345
class SomeClass with Diagnosticable {}

class State<T> with Diagnosticable {}

class StateA extends State {}

class StateB extends State<int> {}

StateA a = StateA();
StateB b = StateB();

foo<T>(T x) {
  print(T);
}

main() {
  var x = a ?? b;
  foo(x);
}
