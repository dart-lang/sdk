// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';

import 'incremental_load_from_dill_suite.dart'
    show TestIncrementalCompiler, getOptions;

main() async {
  await compile("import 'foo.dart' if (dart.library.bar) 'baz.dart';");
}

void compile(String data) async {
  Uri base = Uri.parse("org-dartlang-test:///");
  Uri sdkSummary = base.resolve("nonexisting.dill");
  Uri mainFile = base.resolve("main.dart");
  MemoryFileSystem fs = new MemoryFileSystem(base);
  CompilerOptions options = getOptions();
  options.fileSystem = fs;
  options.sdkRoot = null;
  options.sdkSummary = sdkSummary;
  options.librariesSpecificationUri = null;
  options.omitPlatform = true;
  options.onDiagnostic = (DiagnosticMessage message) {
    // ignored
  };
  fs.entityForUri(mainFile).writeAsStringSync(data);
  TestIncrementalCompiler compiler =
      new TestIncrementalCompiler(options, mainFile);
  await compiler.computeDelta();
}
