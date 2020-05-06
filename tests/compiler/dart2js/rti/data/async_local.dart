// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() async {
  // With the `is dynamic Function(Object,StackTrace)` test in the async
  // implementation the closure, with type `dynamic Function(dynamic, dynamic)`,
  // needs its signature.
  //
  // This happens because the closure is thought as possibly going to the
  // async.errorHandler callback.

  /*needsSignature*/
  local(object, stacktrace) => null;

  return local;
}
