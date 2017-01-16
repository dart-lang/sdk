// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to errors during startup of the process.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:io';

// Constants from errno.h
const ENOENT = 2;
const EACCES = 13;

// TODO(http://dartbug.com/28299) This code is added in attempt to collect more
// information about the flakyness this test experiences on Android bots:
// sometimes the test fails because we get EACCES instead of ENOENT error
// from the OS.
checkForAccessError(error) {
  if (error.errorCode == EACCES) {
    report(obj) {
      final stat = obj.statSync();
      print("${obj} | ${stat.type} | ${stat.modeString()}");
    }

    report(Directory.current);
    report(new File("__path_to_something_that_should_not_exist__"));
  }
}

testStartError() {
  Future<Process> processFuture =
      Process.start("__path_to_something_that_should_not_exist__",
                    const []);
  processFuture.then((p) => Expect.fail('got process despite start error'))
  .catchError((error) {
    Expect.isTrue(error is ProcessException);
    checkForAccessError(error);
    Expect.equals(ENOENT, error.errorCode, error.toString());
  });
}

testRunError() {
  Future<ProcessResult> processFuture =
      Process.run("__path_to_something_that_should_not_exist__",
                  const []);

  processFuture.then((result) => Expect.fail("exit handler called"))
  .catchError((error) {
    Expect.isTrue(error is ProcessException);
    checkForAccessError(error);
    Expect.equals(ENOENT, error.errorCode, error.toString());
  });
}

main() {
  testStartError();
  testRunError();
}
