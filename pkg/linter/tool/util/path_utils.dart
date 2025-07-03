// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:path/path.dart' as path;

final String linterPackageRoot = path.normalize(
  path.join(pkg_root.packageRoot, 'linter'),
);

String pathRelativeToPackageRoot(Iterable<String> parts) =>
    path.joinAll([linterPackageRoot, ...parts]);

String pathRelativeToPkgDir(Iterable<String> parts) =>
    path.joinAll([pkg_root.packageRoot, ...parts]);
