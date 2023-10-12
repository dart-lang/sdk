// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  C(arg) {
    print(arg);
  }
  void instanceMethod(arg) {
    print(arg);
  }

  static void staticMethod(arg) {
    print(arg);
  }
}

dynamic createClosure1() => (arg) => print(arg);

dynamic createClosure2() {
  void inner(arg) {
    print(arg);
  }

  return inner;
}

dynamic createClosure3(obj) => obj.instanceMethod;

dynamic createClosure4() => C.staticMethod;

dynamic createClosure5() => C.new;

void useClosure11(void Function(dynamic) func) {
  func(42);
}

void useClosure12(void Function(dynamic) func) {
  func(42);
}

void useClosure13(void Function(dynamic) func) {
  func(42);
}

void useClosure14(void Function(dynamic) func) {
  func(42);
}

void useClosure15(void Function(dynamic) func) {
  func(42);
}

void useClosure21(func) {
  func(42);
}

void useClosure22(func) {
  func(42);
}

void useClosure23(func) {
  func(42);
}

void useClosure24(func) {
  func(42);
}

void useClosure25(func) {
  func(42);
}

class UseClosure31 {
  final void Function(dynamic) func;
  UseClosure31(this.func);
  void use() {
    func(42);
  }
}

class UseClosure32 {
  final void Function(dynamic) func;
  UseClosure32(this.func);
  void use() {
    func(42);
  }
}

class UseClosure33 {
  final void Function(dynamic) func;
  UseClosure33(this.func);
  void use() {
    func(42);
  }
}

class UseClosure34 {
  final void Function(dynamic) func;
  UseClosure34(this.func);
  void use() {
    func(42);
  }
}

class UseClosure35 {
  final void Function(dynamic) func;
  UseClosure35(this.func);
  void use() {
    func(42);
  }
}

void main() {
  useClosure11(createClosure1());
  useClosure12(createClosure2());
  useClosure13(createClosure3(C(3)));
  useClosure14(createClosure4());
  useClosure15(createClosure5());

  useClosure21(createClosure1());
  useClosure22(createClosure2());
  useClosure23(createClosure3(C(3)));
  useClosure24(createClosure4());
  useClosure25(createClosure5());

  UseClosure31(createClosure1()).use();
  UseClosure32(createClosure2()).use();
  UseClosure33(createClosure3(C(3))).use();
  UseClosure34(createClosure4()).use();
  UseClosure35(createClosure5()).use();
}
