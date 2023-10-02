// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart';
import 'package:front_end/src/testing/analysis_helper.dart';
import 'package:front_end/src/testing/dynamic_analysis.dart';
import 'package:kernel/ast.dart';

Future<void> main(List<String> args) async {
  await run(dartdevcEntryPoints,
      'pkg/dev_compiler/test/dynamic/dartdevc_allowed.json',
      analyzedUrisFilter: dartdevcOnly,
      verbose: args.contains('-v'),
      generate: args.contains('-g'));
}

Future<void> run(List<Uri> entryPoints, String allowedListPath,
    {bool verbose = false,
    bool generate = false,
    bool Function(Uri uri)? analyzedUrisFilter}) async {
  await runAnalysis(entryPoints,
      (DiagnosticMessageHandler onDiagnostic, Component component) {
    DynamicVisitor(onDiagnostic, component, allowedListPath, analyzedUrisFilter)
        .run(verbose: verbose, generate: generate);
  });
}

/// Entry points used for analyzing dartdevc code.
final List<Uri> dartdevcEntryPoints = [
  Uri.base.resolve('pkg/dev_compiler/bin/dartdevc.dart')
];

/// Filter function used to only analyze dartdevc source code.
bool dartdevcOnly(Uri uri) {
  var text = '$uri';
  for (var path in [
    'package:_js_interop_checks/',
    'package:dev_compiler/',
  ]) {
    if (text.startsWith(path)) {
      return true;
    }
  }
  return false;
}
