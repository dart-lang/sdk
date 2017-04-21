// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A simple test that ensure that reflection works on uninstantiated classes.

library lib;

@MirrorsUsed(targets: "lib")
import "dart:mirrors";

class Foo {
  int a;
}

main() {
  // Do NOT instantiate Foo.
  var m = reflectClass(Foo);
  var field = publicFields(m).single;
  if (MirrorSystem.getName(field.simpleName) != 'a') {
    throw 'Expected "a", but got "${MirrorSystem.getName(field.simpleName)}"';
  }
  print(field);
}

publicFields(ClassMirror mirror) => mirror.declarations.values
    .where((x) => x is VariableMirror && !(x.isPrivate || x.isStatic));
