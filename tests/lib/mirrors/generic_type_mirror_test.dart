// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";
import "package:expect/expect.dart";

class Foo<W, V> {
  V field;
  V get bar => field;
  set bar(V v) {}
  W m() {}
  V n() {}
  o(W w) {}
}

class Bar {}
class Baz {}

main() {
  testInstance();
  testOriginalDeclaration();
}

void testInstance() {
  ClassMirror foo = reflect((new Foo<Bar, Baz>())).type;
  ClassMirror bar = reflect(new Bar()).type;
  ClassMirror baz = reflect(new Baz()).type;
  VariableMirror field = foo.variables.values.single;
  MethodMirror getter = foo.getters.values.single;
  MethodMirror setter = foo.setters.values.single;
  MethodMirror m = foo.methods[const Symbol('m')];
  MethodMirror n = foo.methods[const Symbol('n')];
  MethodMirror o = foo.methods[const Symbol('o')];

  Expect.equals(foo, field.owner);
  Expect.equals(foo, getter.owner);
  Expect.equals(foo, setter.owner);
  Expect.equals(foo, m.owner);
  Expect.equals(foo, n.owner);
  Expect.equals(foo, o.owner);

  Expect.equals(baz, field.type); /// 01: ok
  Expect.equals(baz, getter.returnType);
  Expect.equals(bar, m.returnType);
  Expect.equals(baz, n.returnType);
  Expect.equals(bar, o.parameters.single.type);
  Expect.equals(baz, setter.parameters.single.type);

}

void testOriginalDeclaration() {
  ClassMirror foo = reflectClass(Foo);

  VariableMirror field = foo.variables.values.single;
  MethodMirror getter = foo.getters.values.single;
  MethodMirror setter = foo.setters.values.single;
  MethodMirror m = foo.methods[const Symbol('m')];
  MethodMirror n = foo.methods[const Symbol('n')];
  MethodMirror o = foo.methods[const Symbol('o')];
  TypeVariableMirror w = foo.typeVariables[0];
  TypeVariableMirror v = foo.typeVariables[1];

  Expect.equals(foo, field.owner);
  Expect.equals(foo, getter.owner);
  Expect.equals(foo, setter.owner);
  Expect.equals(foo, m.owner);
  Expect.equals(foo, n.owner);
  Expect.equals(foo, o.owner);

  Expect.equals(v, field.type); /// 01: ok
  Expect.equals(v, getter.returnType);
  Expect.equals(w, m.returnType);
  Expect.equals(v, n.returnType);
  Expect.equals(w, o.parameters.single.type);
  Expect.equals(v, setter.parameters.single.type);

}