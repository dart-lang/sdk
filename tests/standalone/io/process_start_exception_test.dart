// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to errors during startup of the process.

#import("dart:io");

testStartError() {
  Future<Process> processFuture =
      Process.start("__path_to_something_that_should_not_exist__",
                    const []);
  processFuture.then((p) => Expect.fail('got process despite start error'));
  processFuture.handleException((e) {
    Expect.isTrue(e is ProcessException);
    Expect.equals(2, e.errorCode, e.toString());
    return true;
  });
}

testRunError() {
  Future<ProcessResult> processFuture =
      Process.run("__path_to_something_that_should_not_exist__",
                  const []);

  processFuture.then((result) => Expect.fail("exit handler called"));

  processFuture.handleException((e) {
    Expect.isTrue(e is ProcessException);
    Expect.equals(2, e.errorCode, e.toString());
    return true;
  });
}

main() {
  testStartError();
  testRunError();
}
