// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This is a companion script to print_test.dart.

import 'dart:convert';
import 'dart:io';
import 'dart:async';

class ToString {
  String _toString;

  ToString(this._toString);

  String toString() => _toString;
}

main(List<String> arguments) {
  switch (arguments[0]) {
    case "--eol=default":
      break;
    case "--eol=windows":
      stdout.lineTerminator = '\r\n';
      break;
    case "--eol=unix":
      stdout.lineTerminator = '\n';
      break;
    default:
      stderr.writeln("eol mode not recognized: ${arguments[0]}");
      exit(1);
      break;
  }

  if (!arguments[1].startsWith("--encoding=")) {
    stderr.writeln("encoding not recognized: ${arguments[0]}");
    exit(1);
  }

  stdout.encoding =
      Encoding.getByName(arguments[1].replaceFirst("--encoding=", ""))!;

  switch (arguments.last) {
    case "byte-list-hello":
      stdout.add([104, 101, 108, 108, 111, 10]);
      break;
    case "byte-list-allo":
      stdout.add([97, 108, 108, 244, 10]);
      break;
    case "stream-hello":
      var controller = new StreamController<List<int>>(sync: true);
      stdout.addStream(controller.stream);
      controller.add([104, 101, 108, 108]);
      controller.add([111, 10]);
      controller.close();
      break;
    case "stream-allo":
      var controller = new StreamController<List<int>>(sync: true);
      stdout.addStream(controller.stream);
      controller.add([97, 108, 108]);
      controller.add([244, 10]);
      controller.close();
      break;
    case "string-hello":
      stdout.write('hello\n');
      break;
    case "string-allo":
      stdout.write('allô\n');
      break;
    case "string-internal-linefeeds":
      stdout.write("l1\nl2\nl3");
      break;
    case "string-internal-carriagereturns":
      stdout.write("l1\rl2\rl3\r");
      break;
    case "string-internal-carriagereturn-linefeeds":
      stdout.write("l1\r\nl2\r\nl3\r\n");
      break;
    case "string-carriagereturn-linefeed-seperate-write":
      stdout.write("l1\r");
      stdout.write("\nl2");
      break;
    case "string-carriagereturn-writeln":
      stdout.write("l1\r");
      stdout.writeln();
      break;
    case "write-char-code-linefeed":
      stdout.write("l1");
      stdout.writeCharCode(10);
    case "write-char-code-linefeed-after-carriagereturn":
      stdout.write("l1\r");
      stdout.writeCharCode(10);
    case "object-internal-linefeeds":
      print(ToString("l1\nl2\nl3"));
      break;
    default:
      stderr.writeln("Command was not recognized");
      exit(1);
      break;
  }
}
