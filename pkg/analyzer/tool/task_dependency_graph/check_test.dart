// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library task_dependency_graph.check_test;

import 'dart:io';

import 'package:path/path.dart';

import 'generate.dart';

/**
 * Check that the target file has been code generated.  If it hasn't tell the
 * user to run generate.dart.
 */
main() {
  String script = Platform.script.toFilePath(windows: Platform.isWindows);
  Driver driver = new Driver();
  if (!driver.checkFile()) {
    print('${driver.file.absolute} does not have expected contents.');
    print('Please regenerate using:');
    String executable = Platform.executable;
    String packageRoot = '';
    if (Platform.packageRoot.isNotEmpty) {
      packageRoot = ' --package-root=${Platform.packageRoot}';
    }
    String generateScript = join(dirname(script), 'generate.dart');
    print('  $executable$packageRoot $generateScript');
    exit(1);
  } else {
    print('Generated file is up to date.');
  }
}
