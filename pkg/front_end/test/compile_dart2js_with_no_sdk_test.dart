// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/compiler_options.dart';

import 'incremental_load_from_dill_suite.dart'
    show TestIncrementalCompiler, getOptions;

main() async {
  final Uri dart2jsUrl = Uri.base.resolve("pkg/compiler/bin/dart2js.dart");
  CompilerOptions options = getOptions();
  options.sdkSummary = options.sdkSummary.resolve("nonexisting.dill");
  options.librariesSpecificationUri = null;
  int diagnosticCount = 0;
  options.onDiagnostic = (DiagnosticMessage message) {
    // ignoring
    diagnosticCount++;
  };
  TestIncrementalCompiler compiler =
      new TestIncrementalCompiler(options, dart2jsUrl);
  await compiler.computeDelta();
  print("Got a total of $diagnosticCount diagnostics.");
  if (diagnosticCount < 10000) {
    // We currently get 43.000+.
    throw "Less diagnostics than expected.";
  }
}
