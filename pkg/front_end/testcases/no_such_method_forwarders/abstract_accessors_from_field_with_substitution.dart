// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that noSuchMethod forwarders that are generated for abstract
// accessors synthesized from a field of an interface have the proper type
// substitution performed on the types of their parameters and on the return
// type.

void expectTypeError(callback()) {
  try {
    callback();
    throw 'Expected TypeError, did not occur';
  } on TypeError {}
}

abstract class A<X> {
  List<X> foo;
}

class B implements A<int> {
  dynamic noSuchMethod(i) => <dynamic>[];

  // The noSuchMethod forwarder for the getter should return `List<int>`.

  // The noSuchMethod forwarder for the setter should take `List<int>`.
}

main() {
  var b = new B();
  expectTypeError(() => b.foo);
  expectTypeError(() => (b as dynamic).foo = <dynamic>[]);
}
