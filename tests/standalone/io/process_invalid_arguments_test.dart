// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test that invalid arguments throw exceptions.

import "package:expect/expect.dart";
import "dart:io";

void main() {
  Expect.throws(() => Process.start(["true"], []), (e) => e is ArgumentError);
  Expect.throws(() => Process.start("true", "asdf"), (e) => e is ArgumentError);
  Expect.throws(
      () => Process.start("true", ["asdf", 1]), (e) => e is ArgumentError);
  ;
  Expect.throws(() => Process.start("true", [], workingDirectory: 23),
      (e) => e is ArgumentError);
  Expect.throws(() => Process.run("true", [], workingDirectory: 23),
      (e) => e is ArgumentError);

  Process
      .run("true", [], stdoutEncoding: 23)
      .then((_) => Expect.fail("expected error"), onError: (_) {});

  Process
      .run("true", [], stderrEncoding: 23)
      .then((_) => Expect.fail("expected error"), onError: (_) {});
}
