// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Struct {}

class StructA extends Struct {}

class StructB extends Struct {}

class NonStruct {}

extension Extension<T extends Struct?> on T {
  T method() => this;
  T get property => this;
  void set property(T value) {}
}

main() {
  Struct? struct;
  StructA? structA;
  StructB? structB;

  struct.method();
  struct.property = struct.property;
  struct.property = structA.property;
  struct.property = structB.property;
  structA.method();
  structA.property = structA.property;
  structB.method();
  structB.property = structB.property;

  new Struct().method();
  new Struct().property;
  struct.property = null;
  new StructA().method();
  new StructA().property;
  structA.property = null;
  new StructB().method();
  new StructB().property;
  structB.property = null;
}

errors() {
  Struct? struct;
  StructA? structA;
  StructB? structB;

  structA.property = struct.property; // error
  structB.property = struct.property; // error

  new Struct().property = null; // error
  new StructA().property = null; // error
  new StructB().property = null; // error
}

testNonStruct() {
  NonStruct nonStruct;
  nonStruct.method(); // error
  nonStruct.property = nonStruct.property; // error
  new NonStruct().method(); // error
  new NonStruct().property; // error
  new NonStruct().property = null; // error
}
