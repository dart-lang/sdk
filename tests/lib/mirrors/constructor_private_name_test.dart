// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for C1 bug.

import 'dart:mirrors';

import 'package:expect/expect.dart';

class Foo {
  Foo._private();
}

class _Foo {
  _Foo._private();
}

main() {
  ClassMirror fooMirror = reflectClass(Foo);
  Symbol constructorName = constructorNameFor(fooMirror, "Foo._private");
  Expect.notEquals(#Foo._private, constructorName); // It's private.
  fooMirror.newInstance(constructorName, []);

  ClassMirror _fooMirror = reflectClass(_Foo);
  constructorName = constructorNameFor(_fooMirror, "_Foo._private");
  Expect.notEquals(#_Foo._private, constructorName); // It's private.
  _fooMirror.newInstance(constructorName, []);
}

// There is no way to construct a constructor name with a private class
// or base name. Using `#_Foo._private` creates a library name which does not
// have privacy.
Symbol constructorNameFor(ClassMirror cm, String name) =>
    (cm.declarations.values.firstWhere(
              (d) => MirrorSystem.getName(d.simpleName) == name,
            )
            as MethodMirror)
        .constructorName;
