// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:json";

void test(String line, List<String> expected) {
  var script = new Path(Platform.script).directoryPath;
  script = script.append("stdin_sync_script.dart");
  Process.start(Platform.executable,
                [script.toNativePath()]..addAll(
                    expected.map(stringify))).then((process) {
    process.stdin.write(line);
    process.stdin.close();
    process.stderr
        .transform(new StringDecoder())
        .transform(new LineTransformer())
        .fold(new StringBuffer(), (b, d) => b..write(d))
        .then((data) {
          if (data.toString() != '') throw "Bad output: '$data'";
        });
    process.stdout
        .transform(new StringDecoder())
        .transform(new LineTransformer())
        .fold(new StringBuffer(), (b, d) => b..write(d))
        .then((data) {
          if (data.toString() != 'true') throw "Bad output: '$data'";
        });
  });
}

void main() {
  test("hej\x01\x00\x0d\x0a\x0a4\x0a", ['hej\x01\x00', '', '4']);

  test("hej\u0187", ['hej\u0187']);

  test("hej\rhej\nhej\r", ['hej\rhej', 'hej\r']);

  if (Platform.isWindows) {
    // Windows trim one of the \r.
    test("hej\r\r\r\nhej\r\nhej\r", ['hej\r', 'hej', 'hej\r']);
  } else {
    test("hej\r\r\nhej\r\nhej\r", ['hej\r', 'hej', 'hej\r']);
  }

  test("hej", ['hej']);
}
