// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Utility script to echo strings in various formats to stdout or
// stderr.

import "dart:convert";
import "dart:io";

writeData(data, encoding, stream) {
  if (stream == "stdout") {
    if (encoding == null) {
      stdout.add(data);
    } else {
      stdout.encoding = encoding;
      stdout.write(data);
    }
  } else if (stream == "stderr") {
    if (encoding == null) {
      stderr.add(data);
    } else {
      stderr.encoding = encoding;
      stderr.write(data);
    }
  }
}

main(List<String> arguments) {
  var asciiString = 'abc';
  var latin1String = 'æøå';
  var utf8String = new String.fromCharCodes([955]);
  var binary = [0, 1, 2];
  if (arguments.length > 1) {
    var stream = arguments[1];
    if (arguments[0] == "ascii") {
      writeData(asciiString, ASCII, stream);
    } else if (arguments[0] == "latin1") {
      writeData(latin1String, LATIN1, stream);
    } else if (arguments[0] == "utf8") {
      writeData(utf8String, UTF8, stream);
    } else if (arguments[0] == "binary") {
      writeData(binary, null, stream);
    }
  }
}
