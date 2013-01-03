// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

main() {
  Directory temp = new Directory('').createTempSync();
  File script = new File('${temp.path}/script.dart');
  script.writeAsStringSync("""
import 'dart:io';

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
  ProcessOptions options = new ProcessOptions();
  options.workingDirectory = temp.path;
  String executable = new File(new Options().executable).fullPathSync();
  Process.run(executable, ['script.dart'], options).then((result) {
    temp.deleteSync(recursive: true);
    Expect.equals(0, result.exitCode);
  });
}
