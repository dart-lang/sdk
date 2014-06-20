// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'memory_source_file_helper.dart';
import "package:async_helper/async_helper.dart";

import 'package:compiler/compiler.dart'
       show Diagnostic;

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

  Compiler compiler = new Compiler(provider.readStringFromUri,
                                   (name, extension) => null,
                                   diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   ['--analyze-only'],
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
