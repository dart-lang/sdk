// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'memory_source_file_helper.dart';
import "package:async_helper/async_helper.dart";

import 'package:compiler/compiler.dart'
       show Diagnostic;
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/old_to_new_api.dart';

main() {
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  var provider = new MemorySourceFileProvider(MEMORY_SOURCE_FILES);
  int warningCount = 0;
  int errorCount = 0;
  void diagnosticHandler(Uri uri, int begin, int end,
                         String message, Diagnostic kind) {
    if (kind == Diagnostic.VERBOSE_INFO) {
      return;
    }
    if (kind == Diagnostic.ERROR) {
      errorCount++;
    } else if (kind == Diagnostic.WARNING) {
      warningCount++;
    } else {
      throw 'unexpected diagnostic $kind: $message';
    }
  }

  CompilerImpl compiler = new CompilerImpl(
      new LegacyCompilerInput(provider.readStringFromUri),
      new LegacyCompilerOutput(),
      new LegacyCompilerDiagnostics(diagnosticHandler),
      libraryRoot,
      packageRoot,
      [Flags.analyzeOnly],
      {});
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    Expect.isTrue(compiler.compilationFailed);
    Expect.equals(5, errorCount);
    Expect.equals(1, warningCount);
  }));
}

const Map MEMORY_SOURCE_FILES = const {
  'main.dart': """
main() {
  for (var x, y in []) {
  }

  for (var x = 10 in []) {
  }

  for (x.y in []) { // Also causes a warning "x unresolved".
  }

  for ((){}() in []) {
  }

  for (1 in []) {
  }
}
"""
};
