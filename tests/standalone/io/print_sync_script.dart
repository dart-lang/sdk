// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

String get bigString {
  var buffer = new StringBuffer();
  for (var i = 0; i < 1000; i++) {
    buffer.write(i);
    for (var i = 0; i < 200; i++) {
      buffer.write('=');
    }
    buffer.writeln();
  }
  return buffer.toString();
}

main() {
  stdout; // Be sure to mark stdout as non-blocking.
  print(bigString);
}
