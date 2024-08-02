// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(dynamic x, dynamic list) {
  return {1: 1, if (list case [int _]) ...x else ...x};
}

main() {
  test({0: 0}, [0]);
  expectThrows<TypeError>(() {test(null, [0]);});
}

expectThrows<Exception>(void Function() f) {
  String? message;
  try {
    f();
    message = "Expected the function to throw an exception, but it didn't.";
  } on Exception catch (_) {
    // Ok.
  } on dynamic catch (e) {
    message = "Expected the function to throw an exception of type '${Exception}', but got '${e.runtimeType}'.";
  }
  if (message != null) {
    throw message;
  }
}
