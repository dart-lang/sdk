// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test that invalid arguments throw exceptions.

#import("dart:io");

void main() {
  Expect.throws(() => new Process.start(["true"], []),
                (e) => e is ProcessException);
  Expect.throws(() => new Process.start("true", "asdf"),
                (e) => e is ProcessException);
  Expect.throws(() => new Process.start("true", ["asdf", 1]),
                (e) => e is ProcessException);
}
