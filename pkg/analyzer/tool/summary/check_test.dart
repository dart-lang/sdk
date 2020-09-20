// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_tool/tools.dart';
import 'package:path/path.dart';

import '../../test/utils/package_root.dart' as package_root;
import 'generate.dart';

/// Check that the target file has been code generated.  If it hasn't tell the
/// user to run generate.dart.
main() async {
  var idlFolderPath = normalize(
      join(package_root.packageRoot, 'analyzer', 'lib', 'src', 'summary'));
  var idlPath = normalize(join(idlFolderPath, 'idl.dart'));
  await GeneratedContent.checkAll(idlFolderPath,
      'pkg/analyzer/tool/summary/generate.dart', getAllTargets(idlPath),
      args: [idlPath]);
}
