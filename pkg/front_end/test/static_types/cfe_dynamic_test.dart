// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/testing/analysis_helper.dart';
import 'package:front_end/src/testing/dynamic_analysis.dart';

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart';
import 'package:kernel/ast.dart';

Future<void> main(List<String> args) async {
  await run(
      cfeOnlyEntryPoints, 'pkg/front_end/test/static_types/cfe_allowed.json',
      analyzedUrisFilter: cfeOnly,
      verbose: args.contains('-v'),
      generate: args.contains('-g'));
}

Future<void> run(List<Uri> entryPoints, String allowedListPath,
    {bool verbose = false,
    bool generate = false,
    bool Function(Uri uri)? analyzedUrisFilter}) async {
  await runAnalysis(entryPoints,
      (DiagnosticMessageHandler onDiagnostic, Component component) {
    new DynamicVisitor(
            onDiagnostic, component, allowedListPath, analyzedUrisFilter)
        .run(verbose: verbose, generate: generate);
  });
}
