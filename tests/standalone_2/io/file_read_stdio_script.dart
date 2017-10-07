// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

void main() {
  var expected = new File(Platform.script.toFilePath()).readAsStringSync();
  var stdin = new File('/dev/fd/0').readAsStringSync();
  if (expected != stdin) {
    throw "stdin not equal expected file";
  }
}
