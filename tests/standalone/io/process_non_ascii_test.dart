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
  var opened = nonAsciiFile.openSync(FileMode.WRITE);
  opened.writeStringSync(
"""
import 'dart:io';

main() {
  Expect.equals('æøå', new File('æøå.txt').readAsStringSync());
}
""");
  opened.closeSync();
  var nonAsciiTxtFile = new File('${nonAsciiDir.path}/æøå.txt');
  opened = nonAsciiTxtFile.openSync(FileMode.WRITE);
  opened.writeStringSync('æøå');
  opened.closeSync();
  var options = new ProcessOptions();
  options.workingDirectory = nonAsciiDir.path;
  var script = nonAsciiFile.name;
  Process.run(executable, [script], options).then((result) {
    Expect.equals(0, result.exitCode);
    tempDir.deleteSync(recursive: true);
    port.close();
  });
}
