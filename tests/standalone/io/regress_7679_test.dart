// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:io';

main() {
  Directory temp = Directory.systemTemp.createTempSync('dart_regress_7679');
  File script = new File('${temp.path}/script.dart');
  script.writeAsStringSync("""
import 'dart:io';

class Expect {
  static void isTrue(var x) {
    if (!identical(x, true)) {
      throw new Error("Not identical");
    }
  }
}

main() {
  Directory d = new Directory('a');
  d.create(recursive: true).then((_) {
    d.exists().then((result) {
      Expect.isTrue(result);
      d = new Directory('b/c/d');
      d.create(recursive: true).then((_) {
        d.exists().then((result) {
          Expect.isTrue(result);
        });
      });
    });
  });
}
""");
  String executable = new File(Platform.executable).resolveSymbolicLinksSync();
  Process
      .run(executable, ['script.dart'], workingDirectory: temp.path)
      .then((result) {
    temp.deleteSync(recursive: true);
    Expect.equals(0, result.exitCode);
  });
}
