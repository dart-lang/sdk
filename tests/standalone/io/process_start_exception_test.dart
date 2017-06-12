// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to errors during startup of the process.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:io';

// ENOENT and ERROR_FILE_NOT_FOUND on Windows both have the same value.
// Note: we are setting PATH to an empty string in tests below because on
// POSIX systems if target binary name does not contain `/` then it is
// searched through PATH and if it is not found anywhere in the PATH
// but some folder in PATH is inaccessible then underlying execvp(...)
// call will return EACCES (13) instead of ENOENT.
// For example on some Android devices PATH would include /sbin with is
// inaccessible - so this test will fail.
const ENOENT = 2;

testStartError() {
  Future<Process> processFuture = Process.start(
      "__path_to_something_that_should_not_exist__", const [],
      environment: {"PATH": ""});
  processFuture
      .then((p) => Expect.fail('got process despite start error'))
      .catchError((error) {
    Expect.isTrue(error is ProcessException);
    Expect.equals(ENOENT, error.errorCode, error.toString());
  });
}

testRunError() {
  Future<ProcessResult> processFuture = Process.run(
      "__path_to_something_that_should_not_exist__", const [],
      environment: {"PATH": ""});

  processFuture
      .then((result) => Expect.fail("exit handler called"))
      .catchError((error) {
    Expect.isTrue(error is ProcessException);
    Expect.equals(ENOENT, error.errorCode, error.toString());
  });
}

main() {
  testStartError();
  testRunError();
}
