// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart';
import 'package:dev_compiler/dev_compiler.dart';
import 'package:front_end/src/testing/analysis_helper.dart';
import 'package:front_end/src/testing/dynamic_analysis.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart';

Future<void> main(List<String> args) async {
  await run('pkg/dev_compiler/test/dynamic/platform_allowed.json',
      verbose: args.contains('-v'), generate: args.contains('-g'));
}

Future<void> run(String allowedListPath,
    {bool verbose = false, bool generate = false}) async {
  await runPlatformAnalysis(DevCompilerTarget(TargetFlags()),
      (DiagnosticMessageHandler onDiagnostic, Component component) {
    DynamicVisitor(onDiagnostic, component, allowedListPath, platformOnly)
        .run(verbose: verbose, generate: generate);
  });
}
