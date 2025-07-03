// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/tools.dart';
import 'package:path/path.dart';

import 'generate_all.dart';

/// Check that all targets have been code generated.  If they haven't tell the
/// user to run generate_all.dart.
Future<void> main() async {
  var pkgPath = normalize(join(pkg_root.packageRoot, 'analysis_server'));
  await GeneratedContent.checkAll(
    pkgPath,
    join(pkgPath, 'tool', 'spec', 'generate_all.dart'),
    allTargets,
  );
}
