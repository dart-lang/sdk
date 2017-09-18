// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.tool.summary.check_test;

import 'package:front_end/src/codegen/tools.dart';
import 'package:front_end/src/testing/package_root.dart' as package_root;
import 'package:path/path.dart';

import 'generate.dart';

/**
 * Check that the target file has been code generated.  If it hasn't tell the
 * user to run generate.dart.
 */
main() async {
  String pkgPath = normalize(join(package_root.packageRoot, 'analyzer'));
  await GeneratedContent.checkAll(
      pkgPath, 'tool/summary/generate.dart', allTargets);
}
