// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test that invalid arguments throw exceptions.

#import("dart:io");

void main() {
  Expect.throws(() => new Process.start(["true"], []),
                (e) => e is IllegalArgumentException);
  Expect.throws(() => new Process.start("true", "asdf"),
                (e) => e is IllegalArgumentException);
  Expect.throws(() => new Process.start("true", ["asdf", 1]),
                (e) => e is IllegalArgumentException);
  Expect.throws(() => new Process.run(["true"], [], null,
                                      (exit, out, err) => null),
                (e) => e is IllegalArgumentException);
  Expect.throws(() => new Process.run("true", "asdf", null,
                                      (exit, out, err) => null),
                (e) => e is IllegalArgumentException);
  Expect.throws(() => new Process.run("true", ["asdf", 1], null,
                                      (exit, out, err) => null),
                (e) => e is IllegalArgumentException);
  var options = new ProcessOptions();
  options.workingDirectory = 23;
  Expect.throws(() => new Process.start("true", [], options),
                (e) => e is IllegalArgumentException);
  Expect.throws(() => new Process.run("true", [], options,
                                      (exit, out, err) => null),
                (e) => e is IllegalArgumentException);
  options = new ProcessOptions();
  options.stdoutEncoding = 23;
  Expect.throws(() => new Process.run("true", [], options,
                                      (exit, out, err) => null),
                (e) => e is IllegalArgumentException);
  options = new ProcessOptions();
  options.stderrEncoding = 23;
  Expect.throws(() => new Process.run("true", [], options,
                                      (exit, out, err) => null),
                (e) => e is IllegalArgumentException);
}
