// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/tools.dart';

import 'codegen_analysis_server.dart' as codegen_analysis_server;
import 'codegen_dart_notification_handler.dart'
    as codegen_dart_notification_handler;
import 'codegen_dart_protocol.dart' as codegen_dart_protocol;
import 'codegen_inttest_methods.dart' as codegen_inttest_methods;
import 'codegen_java_types.dart' as codegen_java_types;
import 'codegen_matchers.dart' as codegen_matchers;
import 'codegen_protocol_constants.dart' as codegen_protocol_constants;
import 'to_html.dart' as to_html;

/// Generate all targets.
Future<void> main() async {
  await GeneratedContent.generateAll(pkg_root.packageRoot, allTargets);
}

/// Get a list of all generated targets.
List<GeneratedContent> get allTargets {
  var targets = <GeneratedContent>[];
  targets.add(codegen_analysis_server.target);
  targets.add(codegen_dart_notification_handler.clientTarget());
  targets.add(
    codegen_dart_protocol.clientTarget(
      false,
      codegen_dart_protocol.CodegenUriConverterKind.none,
    ),
  );
  targets.add(
    codegen_dart_protocol.serverTarget(
      false,
      codegen_dart_protocol.CodegenUriConverterKind.requiredParameter,
    ),
  );
  targets.add(codegen_java_types.targetDir);
  targets.add(codegen_inttest_methods.target);
  targets.add(codegen_matchers.target);
  targets.add(codegen_protocol_constants.clientTarget);
  targets.add(codegen_protocol_constants.serverTarget);
  targets.add(to_html.target);
  return targets;
}
