// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/55343.
// Verifies that AOT runtime doesn't crash when resolving target of
// a dynamic call when corresponding UnlinkedCall objects are de-duplicated
// and origin function of the UnlinkedCall is not included into the snapshot.

class A {
  @pragma('vm:never-inline')
  void foo() {}

  @pragma('vm:never-inline')
  void bar() {}
}

class B {
  @pragma('vm:never-inline')
  void foo() {
    f1();
  }

  @pragma('vm:never-inline')
  void bar() {}
}

@pragma('vm:entry-point')
dynamic v;

@pragma('vm:never-inline')
void f1() {
  v.bar();
}

@pragma('vm:never-inline')
void f2() {
  v.bar();
}

class G {
  final i;
  const G(this.i);

  @pragma('vm:never-inline')
  void call() {
    f2();
  }
}

void main(List<String> args) {
  v = args.contains('A') ? A() : B();

  // Make sure [G] is marked allocated by backend by allocating it and
  // letting it escape. This will cause [G.call] to be compiled, which
  // will cause [f2] to be compiled.
  print(G(1));
  if (G(1).i != 1) {
    // This code will be pruned by the backend, but not by the TFA:
    // we want TFA to retain [G.call] method.
    G(0).call();
  }

  // We want [f1] to be compiled after [f2] so we use an indirection
  // through a dynamic call.
  v.foo();
}
