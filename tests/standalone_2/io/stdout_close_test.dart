// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";

void main() {
  var dir = Directory.systemTemp.createTempSync('dart_stdout_close');
  stdout.close().then((_) {
    var file = new File('${dir.path}/file');
    var io = file.openSync(mode: FileMode.WRITE);
    print("to file");
    io.closeSync();
    var content = file.readAsStringSync();
    file.deleteSync();
    dir.deleteSync();
    Expect.equals("", content);
  });
}
