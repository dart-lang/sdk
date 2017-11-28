// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

main() {
  if (exitCode != 0) {
    throw "Bad initial exit-code";
  }
  stdout.write("standard out");
  stderr.write("standard error");
  exitCode = 25;
  if (exitCode != 25) {
    throw "Exit-code not set correctly";
  }
}
