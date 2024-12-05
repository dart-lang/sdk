// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/56412.
//
// The combination of named arguments in any position and finalizables leads
// to nested let expressions. Let expressions introduce scopes. Often variables
// get hoisted into a parent scope which is usually a block. But this specific
// regression test has a variable declaration in a let scope.
// (The bug was that in the compiler, let expressions were not entering scopes.)

import 'dart:ffi';

void main() {
  MyFinalizable().myMethod(
    namedArgument: Object(),
    () {
      final error = StateError('Cause crash');
      throw error;
    },
  );
  print('done');
}

class MyFinalizable implements Finalizable {
  Object myMethod(
    Object Function() action, {
    Object? namedArgument,
  }) {
    return Object();
  }
}
