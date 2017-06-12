// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=regress_7191_script.dart

// Regression test for http://dartbug.com/7191.

// Starts a sub-process which in turn starts another sub-process and then closes
// its standard output. If handles are incorrectly inherited on Windows, this
// will lead to a situation where the stdout of the first sub-process is never
// closed which will make this test hang.

import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import 'package:path/path.dart';

main() {
  asyncStart();
  var executable = Platform.executable;
  var script = Platform.script.resolve('regress_7191_script.dart').toFilePath();
  Process.start(executable, [script]).then((process) {
    process.stdin.add([0]);
    process.stdout.listen((_) {}, onDone: () {
      process.stdin.add([0]);
    });
    process.stderr.listen((_) {});
    process.exitCode.then((exitCode) {
      asyncEnd();
      if (exitCode != 0) throw "Bad exit code";
    });
  });
}
