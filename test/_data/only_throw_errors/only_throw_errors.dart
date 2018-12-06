// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';

void throwString() {
  throw 'hello world!'; // LINT
}

void throwNull() {
  throw null; // LINT
}

void throwNumber() {
  throw 7; // LINT
}

void throwObject() {
  throw new Object(); // LINT
}

void throwError() {
  throw new Error(); // OK
}

void throwDynamicPrebuiltError() {
  var error = new Error();
  throw error; // OK
}

void throwStaticPrebuiltError() {
  Error error = new Error();
  throw error; // OK
}

void throwArgumentError() {
  Error error = new ArgumentError('oh!');
  throw error; // OK
}

void throwException() {
  Exception exception = new Exception('oh!');
  throw exception; // OK
}

void throwStringFromFunction() {
  throw returnString(); // LINT
}

String returnString() => 'string!';

void throwExceptionFromFunction() {
  throw returnException();
}

Exception returnException() => new Exception('oh!');

// TODO: Even though in the test this does not get linted, it does while
// analyzing the SDK code. Find out why.
dynamic noSuchMethod(Invocation invocation) {
  throw new NoSuchMethodError(
      new Object(),
      invocation.memberName,
      invocation.positionalArguments,
      invocation.namedArguments);
}

class E extends Object with Exception {
  static throws() {
    throw new E(); // OK
  }
}
