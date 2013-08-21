// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert";
import "dart:io";
import "dart:json";

import "package:path/path.dart";

void testReadByte() {
  void test(String line, List<String> expected) {
    var script = join(dirname(Platform.script), "stdin_sync_script.dart");
    Process.start(Platform.executable,
                  ["--checked", script]..addAll(
                      expected.map(stringify))).then((process) {
      process.stdin.write(line);
      process.stdin.close();
      process.stderr
          .transform(new StringDecoder())
          .transform(new LineSplitter())
          .fold(new StringBuffer(), (b, d) => b..write(d))
          .then((data) {
            if (data.toString() != '') throw "Bad output: '$data'";
          });
      process.stdout
          .transform(new StringDecoder())
          .transform(new LineSplitter())
          .fold(new StringBuffer(), (b, d) => b..write(d))
          .then((data) {
            if (data.toString() != 'true') throw "Bad output: '$data'";
          });
    });
  }

  test("hej\x01\x00\x0d\x0a\x0a4\x0a", ['hej\x01\x00', '', '4']);

  test("hej\u0187", ['hej\u0187']);

  test("hej\rhej\nhej\r", ['hej\rhej', 'hej\r']);

  test("hej\r\r\nhej\r\nhej\r", ['hej\r', 'hej', 'hej\r']);

  test("hej", ['hej']);
}

void testEchoMode() {
  stdin.echoMode = false;
  var line;
  while ((line = stdin.readLineSync()) != null) {
    print("You typed: $line");
  }
}

void testLineMode() {
  stdin.lineMode = false;
  var char;
  while ((char = stdin.readByteSync()) != -1) {
    print("You typed: $char");
  }
}


void main() {
  testReadByte();

  // testEchoMode and testLineMode is an developer-interactive test, thus not
  // enabled.
  //testEchoMode();
  //testLineMode();
}
