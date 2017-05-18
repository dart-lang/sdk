// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/codegen/tools.dart';
import 'package:path/path.dart';

import 'codegen_dart_protocol.dart' as codegen_dart_protocol;
import 'codegen_inttest_methods.dart' as codegen_inttest_methods;
import 'codegen_matchers.dart' as codegen_matchers;
import 'codegen_protocol_common.dart' as codegen_protocol_common;
import 'codegen_protocol_constants.dart' as codegen_protocol_constants;
import 'to_html.dart' as to_html;

/**
 * Generate all targets.
 */
main() {
  String script = Platform.script.toFilePath(windows: Platform.isWindows);
  String pkgPath = normalize(join(dirname(script), '..', '..'));
  GeneratedContent.generateAll(pkgPath, allTargets);
}

/**
 * Get a list of all generated targets.
 */
List<GeneratedContent> get allTargets {
  List<GeneratedContent> targets = <GeneratedContent>[];
  targets.add(codegen_dart_protocol.target(true));
  targets.add(codegen_inttest_methods.target);
  targets.add(codegen_matchers.target);
  targets.add(codegen_protocol_common.target(true));
  targets.add(codegen_protocol_constants.target);
  targets.add(to_html.target);
  return targets;
}
