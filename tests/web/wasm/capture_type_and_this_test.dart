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

main() {
  final a = A<String>();

  if (!identical(a, capturedThis)) {
    throw 'Should have captured the correct `this`.';
  }
  if (!identical(String, capturedType)) {
    throw 'Should have captured the correct `T`.';
  }
}
