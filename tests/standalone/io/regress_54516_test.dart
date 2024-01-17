// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=regress_54516_test.sh

import 'dart:io';

import 'package:expect/expect.dart';

Future<void> main() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return; // executable bit not setup for the shell script.
  }
  // Create a shell script that prints the output.
  final origDir = Directory.current;
  final fileName = "tests/standalone/io/regress_54516_test.sh";
  var script = new File("tests/standalone/io/regress_54516_test.sh");
  if (!script.existsSync()) {
    script = new File("../tests/standalone/io/regress_54516_test.sh");
  }
  var expectedResult = fileName + Platform.lineTerminator;
  Expect.isTrue(script.existsSync());
  List<String> args = [];
  var result = Process.runSync(script.path, args, runInShell: false);
  Expect.stringEquals(result.stdout, expectedResult);
  result = Process.runSync(script.path, args, runInShell: true);
  Expect.stringEquals(result.stdout, expectedResult);
}
