#!/usr/bin/env dart
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// For each codegen test file, this generates a little HTML page that you can
/// load directly in your browser to run and debug the test.
// TODO(rnystrom): This script is still pretty rough around the edges. Use it
// with caution and fix stuff if you see it doing something dumb.

import 'dart:io';

import 'package:path/path.dart' as p;

final scriptDir = p.dirname(p.fromUri(Platform.script));
final ddcDir = p.dirname(scriptDir);

main() {
  var expectDir = p.normalize(p.join(scriptDir, "../test/codegen/expect"));

  var tests = new Directory(expectDir)
      .listSync(recursive: true)
      .map((entry) => p.relative(entry.path, from: expectDir))
      .where((path) => path.endsWith(".js") || path.endsWith(".err"))
      .map(p.withoutExtension)
      .toSet()
      .toList();

  // TODO(rnystrom): Do something more graceful than blowing away the whole
  // directory.
  new Directory("debug").deleteSync(recursive: true);

  tests.forEach(makePage);
}

void makePage(String test) {
  // Create the containing directory if needed.
  var dir = new Directory(p.join(ddcDir, "debug", p.dirname(test)));
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // Make a header line that links to all of the directories.
  var parts = p.split(p.normalize(p.join("debug", p.dirname(test))));
  var headers = [];
  var i = parts.length;
  for (var part in parts) {
    headers.add('<a href="${'../' * i}$part">$part</a>');
    i--;
  }
  var header = headers.join(' / ');

  var toRoot = p.relative(ddcDir, from: dir.path);
  new File(p.join("debug", "$test.html")).writeAsStringSync("""
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-type" content="text/html;charset=UTF-8" />
  <title>$test</title>
</head>
<body>
  <h1>$header / ${p.basename(test)}</h1>
  <h3>Errors</h3>
  <iframe src="$toRoot/test/codegen/expect/$test.err" width="80%"></iframe>
  <h3>Warnings</h3>
  <iframe src="$toRoot/test/codegen/expect/$test.txt" width="80%"></iframe>
  <script src="$toRoot/lib/runtime/dart_library.js"></script>
  <script src="$toRoot/lib/runtime/dart_sdk.js"></script>
  <script src="$toRoot/test/codegen/expect/expect.js"></script>
  <script src="$toRoot/test/codegen/expect/$test.js"></script>
<script>
dart_library.start('$test', '${p.basename(test)}');
</script>
</body>
</html>
""");
}
