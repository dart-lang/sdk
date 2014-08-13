// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library generate.all;

import 'dart:io';

import 'package:path/path.dart';

import 'codegen_tools.dart';
import 'codegen_analysis_server.dart' as codegen_analysis_server;
import 'codegen_inttest_methods.dart' as codegen_inttest_methods;
import 'codegen_matchers.dart' as codegen_matchers;
import 'to_html.dart' as to_html;

/**
 * Get a list of all generated targets.
 */
List<GeneratedFile> get allTargets {
  List<GeneratedFile> targets = <GeneratedFile>[];
  targets.add(codegen_analysis_server.target);
  targets.add(codegen_inttest_methods.target);
  targets.add(codegen_matchers.target);
  targets.add(to_html.target);
  return targets;
}

/**
 * Generate all targets
 */
main() {
  String script = Platform.script.toFilePath(windows: Platform.isWindows);
  Directory.current = new Directory(dirname(script));
  for (GeneratedFile generatedFile in allTargets) {
    generatedFile.generate();
  }
}
