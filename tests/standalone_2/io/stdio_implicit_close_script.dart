// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

void main(List<String> arguments) {
  // Access stdout and stderr so that the system grabs a handle to it. This
  // initializes some internal structures.
  if (stdout.hashCode == -1234 && stderr.hashCode == (stderr.hashCode + 1)) {
    throw "we have other problems.";
  }

  if (arguments.contains("stdout")) {
    stdout.close();
  }
  if (arguments.contains("stderr")) {
    stderr.close();
  }
}
