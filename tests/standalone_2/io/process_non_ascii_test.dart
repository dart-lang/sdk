// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

main() {
  asyncStart();
  var executable = new File(Platform.executable).resolveSymbolicLinksSync();
  var tempDir = Directory.systemTemp.createTempSync('dart_process_non_ascii');
  var nonAsciiDir = new Directory('${tempDir.path}/æøå');
  nonAsciiDir.createSync();
  var nonAsciiFile = new File('${nonAsciiDir.path}/æøå.dart');
  nonAsciiFile.writeAsStringSync("""
import 'dart:io';

main() {
  if ('æøå' != new File('æøå.txt').readAsStringSync()) {
    throw new StateError("not equal");
  }
}
""");
  var nonAsciiTxtFile = new File('${nonAsciiDir.path}/æøå.txt');
  nonAsciiTxtFile.writeAsStringSync('æøå');
  var script = nonAsciiFile.path;
  Process
      .run(executable, [script], workingDirectory: nonAsciiDir.path)
      .then((result) {
    Expect.equals(0, result.exitCode);
    tempDir.deleteSync(recursive: true);
    asyncEnd();
  });
}
