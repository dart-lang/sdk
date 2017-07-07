// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/codegen/tools.dart';
import 'package:path/path.dart';

import 'generate_all.dart';

/**
 * Check that all targets have been code generated.  If they haven't tell the
 * user to run generate_all.dart.
 */
main() {
  String script = Platform.script.toFilePath(windows: Platform.isWindows);
  List<String> components = split(script);
  int index = components.indexOf('analyzer_plugin');
  String pkgPath = joinAll(components.sublist(0, index + 1));
  GeneratedContent.checkAll(
      pkgPath, join('tool', 'spec', 'generate_all.dart'), allTargets);
}
