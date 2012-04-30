// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Utility script to echo strings in various formats to stdout or
// stderr.

#import("dart:io");

writeData(data, encoding, stream) {
  if (stream == "stdout") {
    stdout.writeString(data, encoding);
  } else if (stream == "stderr") {
    stderr.writeString(data, encoding);
  }
}

main() {
  var asciiString = 'abc';
  var latin1String = 'æøå';
  var utf8String = new String.fromCharCodes([955]);
  var options = new Options();
  if (options.arguments.length > 1) {
    var stream = options.arguments[1];
    if (options.arguments[0] == "ascii") {
      writeData(asciiString, Encoding.ASCII, stream);
    } else if (options.arguments[0] == "latin1") {
      writeData(latin1String, Encoding.ISO_8859_1, stream);
    } else if (options.arguments[0] == "utf8") {
      writeData(utf8String, Encoding.UTF_8, stream);
    }
  }
}
