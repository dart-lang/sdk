// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";
import "package:expect/expect.dart";

class Foo<W, V> {
  late V field;
  V get bar => field;
  set bar(V v) {}
  W m() {
    throw "does-not-return";
  }

  V n() {
    throw "does-not-return";
  }

  H<V> p() {
    throw "does-not-return";
  }

  o(W w) {}
}

class H<T> {}

class Bar {}

class Baz {}

void testInstance() {
  ClassMirror foo = reflect((new Foo<Bar, Baz>())).type;
  ClassMirror bar = reflect(new Bar()).type;
  ClassMirror baz = reflect(new Baz()).type;
  ClassMirror hOfBaz = reflect(new H<Baz>()).type;
  VariableMirror field = foo.declarations[#field] as VariableMirror;
  MethodMirror getter = foo.declarations[#bar] as MethodMirror;
  MethodMirror setter = foo.declarations[const Symbol('bar=')] as MethodMirror;
  MethodMirror m = foo.declarations[#m] as MethodMirror;
  MethodMirror n = foo.declarations[#n] as MethodMirror;
  MethodMirror o = foo.declarations[#o] as MethodMirror;
  MethodMirror p = foo.declarations[#p] as MethodMirror;

  Expect.equals(foo, field.owner);
  Expect.equals(foo, getter.owner);
  Expect.equals(foo, setter.owner);
  Expect.equals(foo, m.owner);
  Expect.equals(foo, n.owner);
  Expect.equals(foo, o.owner);
  Expect.equals(foo, p.owner);

  Expect.equals(baz, field.type);
  Expect.equals(baz, getter.returnType);
  Expect.equals(bar, m.returnType);
  Expect.equals(baz, n.returnType);
  Expect.equals(bar, o.parameters.single.type);
  Expect.equals(hOfBaz, p.returnType);
  Expect.equals(1, p.returnType.typeArguments.length);
  Expect.equals(baz, p.returnType.typeArguments[0]);

  Expect.equals(baz, setter.parameters.single.type);
}

void testOriginalDeclaration() {
  ClassMirror foo = reflectClass(Foo);

  VariableMirror field = foo.declarations[#field] as VariableMirror;
  MethodMirror getter = foo.declarations[#bar] as MethodMirror;
  MethodMirror setter = foo.declarations[const Symbol('bar=')] as MethodMirror;
  MethodMirror m = foo.declarations[#m] as MethodMirror;
  MethodMirror n = foo.declarations[#n] as MethodMirror;
  MethodMirror o = foo.declarations[#o] as MethodMirror;
  MethodMirror p = foo.declarations[#p] as MethodMirror;
  TypeVariableMirror w = foo.typeVariables[0] as TypeVariableMirror;
  TypeVariableMirror v = foo.typeVariables[1] as TypeVariableMirror;

  Expect.equals(foo, field.owner);
  Expect.equals(foo, getter.owner);
  Expect.equals(foo, setter.owner);
  Expect.equals(foo, m.owner);
  Expect.equals(foo, n.owner);
  Expect.equals(foo, o.owner);
  Expect.equals(foo, p.owner);

  Expect.equals(v, field.type);
  Expect.equals(v, getter.returnType);
  Expect.equals(w, m.returnType);
  Expect.equals(v, n.returnType);
  Expect.equals(w, o.parameters.single.type);
  Expect.equals(1, p.returnType.typeArguments.length);
  Expect.equals(v, p.returnType.typeArguments[0]);

  Expect.equals(v, setter.parameters.single.type);
}

main() {
  testInstance();
  testOriginalDeclaration();
}
