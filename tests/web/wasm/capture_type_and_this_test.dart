// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

late final Type capturedType;
late final A capturedThis;

class A<T> {
  A() {
    foo() async {
      // This will create a context chain as follows:
      //   Context [T]
      //     `--> Context [<parent-context>, this]
      //            `--> Context [<parent-context, ...]
      capturedType = T;
      capturedThis = this;
    }

    foo();
  }
}

void testThisRestorationInAsyncClosure() {
  final a = A<String>();

  if (!identical(a, capturedThis)) {
    throw 'Should have captured the correct `this`.';
  }
  if (!identical(String, capturedType)) {
    throw 'Should have captured the correct `T`.';
  }
}

late Iterable iterable;

class B<T> {
  B() {
    foo() sync* {
      // This will create a context chain as follows:
      //   Context [T]
      //     `--> Context [<parent-context>, this]
      //            `--> Context [<parent-context, ...]
      yield T;
      yield this;
    }

    iterable = foo();
  }
}

void testThisRestorationInSyncStarClosure() {
  final a = B<String>();

  final it = iterable.iterator;
  if (!it.moveNext()) throw 'expected first element';
  if (!identical(String, it.current)) {
    throw 'Should have captured the correct `T`.';
  }
  if (!it.moveNext()) throw 'expected second element';
  if (!identical(a, it.current)) {
    throw 'Should have captured the correct `this`.';
  }
}

main() {
  testThisRestorationInAsyncClosure();
  testThisRestorationInSyncStarClosure();
}
