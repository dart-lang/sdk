// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library check.all;

import 'dart:io';

import 'package:path/path.dart';

import 'codegen_tools.dart';
import 'generate_all.dart';

/**
 * Check that all targets have been code generated.  If they haven't tell the
 * user to run generate_all.dart.
 */
main() {
  String script = Platform.script.toFilePath(windows: Platform.isWindows);
  Directory.current = new Directory(dirname(script));
  bool generateAllNeeded = false;
  for (GeneratedContent generatedContent in allTargets) {
    if (!generatedContent.check()) {
      print(
          '${generatedContent.outputFile.absolute} does not have expected contents.');
      generateAllNeeded = true;
    }
  }
  if (generateAllNeeded) {
    print('Please regenerate using:');
    String executable = Platform.executable;
    String packageRoot = '';
    if (Platform.packageRoot.isNotEmpty) {
      packageRoot = ' --package-root=${Platform.packageRoot}';
    }
    String generateScript = join(dirname(script), 'generate_all.dart');
    print('  $executable$packageRoot $generateScript');
    exit(1);
  } else {
    print('All generated files up to date.');
  }
}
