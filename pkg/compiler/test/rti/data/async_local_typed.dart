// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*spec.class: Class:explicit=[Class<int*>*],needsArgs*/
class Class<T> {}

main() async {
  // Despite the `is dynamic Function(Object,StackTrace)` test in the async
  // implementation the closure, with type
  // `dynamic Function(dynamic, Class<int>)`, is not a potential subtype and
  // therefore doesn't need its signature.

  /*needsSignature*/
  local(object, Class<int> stacktrace) => null;

  return local;
}
