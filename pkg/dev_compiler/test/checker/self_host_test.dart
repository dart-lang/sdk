// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that run the checker end-to-end using the file system.
library dev_compiler.test.end_to_end;

import 'dart:io';
import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:dev_compiler/devc.dart' show Compiler;
import 'package:dev_compiler/src/options.dart';
import 'package:path/path.dart' as path;
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

main(args) {
  useCompactVMConfiguration();
  var testDir = path.absolute(path.dirname(Platform.script.path));

  test('checker can run on itself ', () {
    var options = new CompilerOptions(
        entryPointFile: '$testDir/../all_tests.dart',
        dartSdkPath: getSdkDir(args).path);
    new Compiler(options).run();
  });
}
