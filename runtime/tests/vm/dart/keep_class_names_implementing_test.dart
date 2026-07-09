// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--keep-class-names-implementing=Exception --keep-class-names-implementing=Error

import "package:expect/expect.dart";

// Can't extend Exception.
class ExceptionImplementor implements Exception {}

class ErrorSubclass extends Error {}

class ErrorImplementor implements Error {
  StackTrace? get stackTrace => null;
}

@pragma("vm:never-inline")
throwException() => throw new Exception();
@pragma("vm:never-inline")
throwExceptionImplementor() => throw new ExceptionImplementor();
@pragma("vm:never-inline")
throwErrorSubclass() => throw new ErrorSubclass();
@pragma("vm:never-inline")
throwErrorImplementor() => throw new ErrorImplementor();

main() {
  try {
    throwException();
  } catch (e) {
    Expect.equals("_Exception", e.runtimeType.toString());
  }

  try {
    throwExceptionImplementor();
  } catch (e) {
    Expect.equals("ExceptionImplementor", e.runtimeType.toString());
  }

  try {
    throwErrorSubclass();
  } catch (e) {
    Expect.equals("ErrorSubclass", e.runtimeType.toString());
  }

  try {
    throwErrorImplementor();
  } catch (e) {
    Expect.equals("ErrorImplementor", e.runtimeType.toString());
  }
}
