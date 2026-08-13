// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_root.dart' as package_root;
import 'package:analyzer_utilities/generated_content_check.dart';
import 'package:path/path.dart';

import 'generate.dart';

/// Check that the target file has been code generated.  If it hasn't tell the
/// user to run generate.dart.
void main() async {
  var idlFolderPath = normalize(
    join(package_root.packageRoot, 'analyzer', 'lib', 'src', 'summary'),
  );
  var idlPath = normalize(join(idlFolderPath, 'idl.dart'));
  await getAllTargets(
    idlPath,
  ).check(package_root.packageRoot, 'pkg/analyzer/tool/summary/generate.dart');
}
