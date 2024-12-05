// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

testList(dynamic x, dynamic list) {
  return [if (list case [int _]) ...x else ...x];
}

testSet(dynamic x, dynamic list) {
  return {0, if (list case [int _]) ...x else ...x};
}

main() {
  testList([0], [0]);
  expectThrows<TypeError>(() {testList(null, [0]);});

  testSet([0], [0]);
  expectThrows<TypeError>(() {testSet(null, [0]);});
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
