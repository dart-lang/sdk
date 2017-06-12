// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that reflection works on methods that would otherwise be
// tree-shaken away.

library lib;

@MirrorsUsed(targets: "lib")
import "dart:mirrors";

class Foo {
  Foo();
  foo() => 42;
}

main() {
  // Do NOT instantiate Foo.
  var m = reflectClass(Foo);
  var instanceMirror = m.newInstance(new Symbol(''), []);
  var result = instanceMirror.invoke(new Symbol('foo'), []).reflectee;
  if (result != 42) {
    throw 'Expected 42, but got $result';
  }
}
