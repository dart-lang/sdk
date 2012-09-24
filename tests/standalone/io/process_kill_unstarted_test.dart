// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test that an unstarted process cannot be killed.

#library("ProcessKillUnstartedTest");
#import("dart:io");

main() {
  var p = Process.start('________', []);
  Expect.throws(p.kill, (e) => e is ProcessException);
  p.onError = (e) => Expect.isTrue(e is ProcessException);
  p.onStart = () => Expect.fail("Process not expected to start");
}
