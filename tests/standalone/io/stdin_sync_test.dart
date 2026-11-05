// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=stdin_sync_script.dart

import "dart:convert";
import "dart:io";

import "package:path/path.dart";
import "package:expect/expect.dart";

Future<void> testReadByte() async {
  test(String line, List<String> expected) async {
    var script = Platform.script.resolve("stdin_sync_script.dart").toFilePath();
    var process = await Process.start(
      Platform.executable,
      []
        ..addAll(Platform.executableArguments)
        ..add('--verbosity=warning')
        ..add(script)
        ..addAll(expected.map(json.encode)),
    );
    process.stdin.write(line);
    process.stdin.flush().then((_) => process.stdin.close());
    process.stderr
        .transform(utf8.decoder)
        .transform(new LineSplitter())
        .fold<StringBuffer>(new StringBuffer(), (b, d) => b..write(d))
        .then((data) {
          if (data.toString() != '') throw "Bad output: '$data'";
        });
    process.stdout
        .transform(utf8.decoder)
        .transform(new LineSplitter())
        .fold<StringBuffer>(new StringBuffer(), (b, d) => b..write(d))
        .then((data) {
          if (data.toString() != 'true') throw "Bad output: '$data'";
        });
    await process.exitCode;
  }

  await test("hej\x01\x00\x0d\x0a\x0a4\x0a", ['hej\x01\x00', '', '4']);

  await test("hej\u0187", ['hej\u0187']);

  await test("hej\rhej\nhej\r", ['hej\rhej', 'hej\r']);

  await test("hej\r\r\nhej\r\nhej\r", ['hej\r', 'hej', 'hej\r']);

  await test("hej", ['hej']);
}

void testEchoMode() {
  stdin.echoMode = true;
  Expect.isTrue(stdin.echoMode);
  stdin.echoMode = false;
  Expect.isFalse(stdin.echoMode);
  var line;
  while ((line = stdin.readLineSync()) != null) {
    print("You typed: $line");
  }
}

void testLineMode() {
  stdin.lineMode = true;
  Expect.isTrue(stdin.lineMode);
  stdin.lineMode = false;
  Expect.isFalse(stdin.lineMode);
  var char;
  while ((char = stdin.readByteSync()) != -1) {
    print("You typed: $char");
  }
}

main() async {
  await testReadByte();

  // testEchoMode and testLineMode is developer-interactive tests, thus not
  // enabled.
  //testEchoMode();
  //testLineMode();
}
