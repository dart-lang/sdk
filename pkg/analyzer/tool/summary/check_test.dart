// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.tool.summary.check_test;

import 'dart:io';

import 'package:analyzer/src/codegen/tools.dart';
import 'package:path/path.dart';

import 'generate.dart';

/**
 * Check that the target file has been code generated.  If it hasn't tell the
 * user to run generate.dart.
 */
main() {
  String script = Platform.script.toFilePath(windows: Platform.isWindows);
  String pkgPath = normalize(join(dirname(script), '..', '..'));
  GeneratedContent.checkAll(pkgPath, 'tool/summary/generate.dart', allTargets);
}
