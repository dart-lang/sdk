// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test that invalid arguments throw exceptions.

#import("dart:io");

void main() {
  Expect.throws(() => Process.start(["true"], []),
                (e) => e is ArgumentError);
  Expect.throws(() => Process.start("true", "asdf"),
                (e) => e is ArgumentError);
  Expect.throws(() => Process.start("true", ["asdf", 1]),
                (e) => e is ArgumentError);
  Expect.throws(() => Process.run(["true"], [], null),
                (e) => e is ArgumentError);
  Expect.throws(() => Process.run("true", "asdf", null),
                (e) => e is ArgumentError);
  Expect.throws(() => Process.run("true", ["asdf", 1], null),
                (e) => e is ArgumentError);
  var options = new ProcessOptions();
  options.workingDirectory = 23;
  Expect.throws(() => Process.start("true", [], options),
                (e) => e is ArgumentError);
  Expect.throws(() => Process.run("true", [], options),
                (e) => e is ArgumentError);
  options = new ProcessOptions();
  options.stdoutEncoding = 23;
  Expect.throws(() => Process.run("true", [], options),
                (e) => e is ArgumentError);
  options = new ProcessOptions();
  options.stderrEncoding = 23;
  Expect.throws(() => Process.run("true", [], options),
                (e) => e is ArgumentError);
}
