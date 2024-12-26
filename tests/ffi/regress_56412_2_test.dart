// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/56412.
//
// Exercises a variable in a parent function that has no name in kernel.
// After a function is compiled in the VM, unnamed variables are renamed to
// "var%i". But the lookup in the inner function still happens with "".

import 'dart:ffi';

void main() async {
  final myInstance = MyClass();
  try {
    await myInstance.callMyMethod();
  } on Exception {
    print('good');
  }
}

final MyFinalizable myFinalizable = MyFinalizable();

class MyClass {
  final int someVeryUniqueVariableName1337plus42 = 3;

  Object callMyMethod() {
    return myFinalizable.myMethod(namedArgument: Object(), () {
      // Force a capture of this.
      // Without capture: `error: expected: delta >= 0`.
      // With capture `error: expected: variable != nullptr`.
      someVeryUniqueVariableName1337plus42;
      throw Exception('Throw something');
    });
  }
}

class MyFinalizable implements Finalizable {
  myMethod(Object Function() action, {Object? namedArgument}) {
    return action();
  }
}
