// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/generated_content_check.dart';
import 'package:path/path.dart';

import 'generate.dart';

/// Check that all targets have been code generated.  If they haven't tell the
/// user to run `generate.dart`.
void main() async {
  String pkgPath = normalize(join(pkg_root.packageRoot, 'analyzer'));
  await (await allTargets).check(
    pkg_root.packageRoot,
    join(pkgPath, 'tool', 'ast', 'generate.dart'),
  );
}
