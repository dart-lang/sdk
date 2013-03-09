// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:io';
import 'dart:isolate';

void main() {
  // temp/
  //   a/
  //     file.txt
  //   b/
  //     a_link -> a
  var d = new Directory("").createTempSync();
  var a = new Directory("${d.path}/a");
  a.createSync();

  var b = new Directory("${d.path}/b");
  b.createSync();

  var f = new File("${d.path}/a/file.txt");
  f.createSync();
  Expect.isTrue(f.existsSync());

  // Create a symlink (or junction on Windows) from
  // temp/b/a_link to temp/a.
  var cmd = "ln";
  var args = ['-s', "${d.path}/b/a_link", "${d.path}/a"];

  if (Platform.operatingSystem == "windows") {
    cmd = "cmd";
    args = ["/c", "mklink", "/j", "${d.path}\\b\\a_link", "${d.path}\\a"];
  }

  var keepAlive = new ReceivePort();

  Process.run(cmd, args).then((_) {
    // Delete the directory containing the junction.
    b.deleteSync(recursive: true);

    // We should not have recursed through a_link into a.
    Expect.isTrue(f.existsSync());

    // Clean up after ourselves.
    d.deleteSync(recursive: true);

    // Terminate now that we are done with everything.
    keepAlive.close();
  });
}
