// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This is a companion script to print_test.dart.

import 'dart:io';

class ToString {
  String _toString;

  ToString(this._toString);

  String toString() => _toString;
}

main(List<String> arguments) {
  switch (arguments.last) {
    case "simple-string":
      print("Hello World");
      break;
    case "string-internal-linefeeds":
      print("l1\nl2\nl3");
      break;
    case "string-internal-carriagereturns":
      print("l1\rl2\rl3\r");
      break;
    case "string-internal-carriagereturn-linefeeds":
      print("l1\r\nl2\r\nl3\r\n");
      break;
    case "object-internal-linefeeds":
      print(ToString("l1\nl2\nl3"));
      break;
    default:
      stderr.writeln("Command was not recognized");
      exit(1);
      break;
  }
}
