// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  testDirectCall();
  testTornOff();
  testCapturedTearOff();
  testTreeShaking();
}

// 1. Non-escaping local functions preserve exact argument and return types.

void testDirectCall() {
  Base passthrough(Base x) {
    x.method();
    return x;
  }

  passthrough(SubA()).method();

  // An escaping use of this local function from an unreachable local function
  // does not widen types on `directOnly`.
  void directOnly(Base x) {
    x.method();
  }

  void unusedTearOff() {
    escapeAndCall(directOnly);
  }

  directOnly(SubA());
}

// 2. Torn-off local functions remain conservatively callable via raw calls.

void testTornOff() {
  void tornOff(Base x) {
    x.method();
  }

  escapeAndCall(tornOff);
}

void testCapturedTearOff() {
  void captured(Base x) {
    x.method();
  }

  () {
    escapeAndCall(captured);
  }();

  captured(SubA());
}

void escapeAndCall(void Function(Base) f) => f(SubB());

abstract class Base {
  void method();
}

class SubA implements Base {
  @override
  void method() => print('SubA');
}

class SubB implements Base {
  @override
  void method() => print('SubB');
}

// 3. Unreachable local functions (and targets only they reference) are shaken.

void testTreeShaking() {
  void unusedSelfReferencing() {
    unusedSelfReferencing();
    print(unusedSelfReferencing);
    onlyCalledFromUnused();
  }

  void unreachableBranch() {
    onlyCalledFromUnreachableBranch();
  }

  if (alwaysFalse()) {
    unreachableBranch();
  }
}

bool alwaysFalse() => false;

void onlyCalledFromUnused() => print('unused');

void onlyCalledFromUnreachableBranch() => print('unreachableBranch');
