// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

main() {
  var scriptDir = new File(new Options().script).directorySync();
  var executable = new File(new Options().executable).fullPathSync();
  var options = new ProcessOptions();
  options.workingDirectory = "${scriptDir.path}/æøå";
  var script = "${scriptDir.path}/æøå.dart";
  print(options.workingDirectory);
  Process.run(executable, [script], options).then((result) {
    Expect.equals(0, result.exitCode);
  });
}
