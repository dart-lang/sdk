// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to errors during startup of the process.

import 'dart:async';
import 'dart:io';

testStartError() {
  Future<Process> processFuture =
      Process.start("__path_to_something_that_should_not_exist__",
                    const []);
  processFuture.then((p) => Expect.fail('got process despite start error'))
  .catchError((e) {
    Expect.isTrue(e.error is ProcessException);
    Expect.equals(2, e.error.errorCode, e.error.toString());
  });
}

testRunError() {
  Future<ProcessResult> processFuture =
      Process.run("__path_to_something_that_should_not_exist__",
                  const []);

  processFuture.then((result) => Expect.fail("exit handler called"))
  .catchError((e) {
    Expect.isTrue(e.error is ProcessException);
    Expect.equals(2, e.error.errorCode, e.error.toString());
  });
}

main() {
  testStartError();
  testRunError();
}
