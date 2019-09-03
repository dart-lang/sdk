// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Struct {}

class StructA extends Struct {}

class StructB extends Struct {}

class NonStruct {}

extension Extension<T extends Struct> on T {
  T method() => this;
  T get property => this;
  void set property(T value) {}
}

main() {
  Struct struct;
  StructA structA;
  StructB structB;

  struct.method();
  struct.property = structA.property;
  structA.method();
  structA.property = struct.property;
  structB.method();
  structB.property = structB.property;

  new Struct().method();
  new Struct().property;
  new Struct().property = null;
  new StructA().method();
  new StructA().property;
  new StructA().property = null;
  new StructB().method();
  new StructB().property;
  new StructB().property = null;
}

testNonStruct() {
  NonStruct nonStruct;
  nonStruct.method();
  nonStruct.property = nonStruct.property;
  new NonStruct().method();
  new NonStruct().property;
  new NonStruct().property = null;
}