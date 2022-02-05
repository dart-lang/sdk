// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.16

import 'dart:ffi';

int doSomething() => 3;

class MyFinalizable implements Finalizable {
  int use() {
    return doSomething();
  }
}

/// Should be transformed into:
///
/// ```
/// int useFinalizableSync(Finalizable finalizable) {
///   final result = doSomething();
///   _reachabilityFence(finalizable);
///   return result;
/// }
/// ```
int useFinalizableSync(Finalizable finalizable) {
  return doSomething();
}

/// Should be transformed into:
///
/// ```
/// void main() {
///   final finalizable = MyFinalizable();
///   print(useFinalizableSync(finalizable));
///   _reachabilityFence(finalizable);
/// }
/// ```
void main() {
  final finalizable = MyFinalizable();
  print(useFinalizableSync(finalizable));
}
