// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

main() {
  var port = new ReceivePort();
  var executable = new File(new Options().executable).fullPathSync();
  var tempDir = new Directory('').createTempSync();
  var nonAsciiDir = new Directory('${tempDir.path}/æøå');
  nonAsciiDir.createSync();
  var nonAsciiFile = new File('${nonAsciiDir.path}/æøå.dart');
  nonAsciiFile.writeAsStringSync(
"""
import 'dart:io';

main() {
  Expect.equals('æøå', new File('æøå.txt').readAsStringSync());
}
""");
  var nonAsciiTxtFile = new File('${nonAsciiDir.path}/æøå.txt');
  nonAsciiTxtFile.writeAsStringSync('æøå');
  var options = new ProcessOptions();
  options.workingDirectory = nonAsciiDir.path;
  var script = nonAsciiFile.name;
  Process.run(executable, [script], options).then((result) {
    Expect.equals(0, result.exitCode);
    tempDir.deleteSync(recursive: true);
    port.close();
  });
}
