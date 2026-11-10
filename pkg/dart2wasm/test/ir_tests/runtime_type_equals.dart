// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=test
// globalFilter=DoesNotMatch
// tableFilter=DoesNotMatch
// compilerOption=-O2

class ClassA(final int x);

class ClassSubA(super.x) extends ClassA;

class ClassB(final int x);

abstract class InterfaceA {}

class ImplA1 implements InterfaceA {}

class ImplA2 implements InterfaceA {}

class GenericClass<T>(final T value);

@pragma('wasm:never-inline')
void sink(bool b) => print(b);

@pragma('wasm:never-inline')
bool testNonGenericNonNullable(ClassA a, ClassB b) {
  return a.runtimeType == b.runtimeType;
}

@pragma('wasm:never-inline')
bool testHierarchy(ClassA a, ClassSubA b) {
  sink(true);
  return a.runtimeType == b.runtimeType;
}

@pragma('wasm:never-inline')
bool testInterface(InterfaceA a, InterfaceA b) {
  sink(false);
  return a.runtimeType == b.runtimeType;
}

@pragma('wasm:never-inline')
bool testLeftNullable(ClassA? a, ClassB b) {
  sink(true);
  return a.runtimeType == b.runtimeType;
}

@pragma('wasm:never-inline')
bool testRightNullable(ClassA a, ClassB? b) {
  sink(false);
  return a.runtimeType == b.runtimeType;
}

@pragma('wasm:never-inline')
bool testBothNullable(ClassA? a, ClassB? b) {
  sink(true);
  return a.runtimeType == b.runtimeType;
}

@pragma('wasm:never-inline')
bool testGenericClass(GenericClass<int> a, GenericClass<String> b) {
  return a.runtimeType == b.runtimeType;
}

void main() {
  final a = ClassA(1);
  final subA = ClassSubA(2);
  final b = ClassB(3);
  final i1 = ImplA1();
  final i2 = ImplA2();
  final g1 = GenericClass<int>(10);
  final g2 = GenericClass<String>('hello');

  sink(testNonGenericNonNullable(a, b));
  sink(testHierarchy(a, subA));
  sink(testInterface(i1, i2));
  sink(testLeftNullable(a, b));
  sink(testLeftNullable(null, b));
  sink(testRightNullable(a, b));
  sink(testRightNullable(a, null));
  sink(testBothNullable(a, b));
  sink(testBothNullable(null, null));
  sink(testGenericClass(g1, g2));
}
