// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart' show Diagnostic;
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

void main() {
  DiagnosticCollector collector = new DiagnosticCollector();
  asyncTest(() async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: MEMORY_SOURCE_FILES,
        diagnosticHandler: collector,
        options: ['--analyze-all']);

    List<String> diagnostics = <String>[];
    collector.messages.forEach((CollectedMessage message) {
      if (message.kind == Diagnostic.VERBOSE_INFO) return;
      diagnostics.add(message.toString());
    });
    diagnostics.sort();
    var expected = [
      "MessageKind.AMBIGUOUS_LOCATION:"
          "memory:exporter.dart:43:49:'hest' is defined here.:info",
      "MessageKind.AMBIGUOUS_LOCATION:"
          "memory:library.dart:41:47:'hest' is defined here.:info",
      "MessageKind.DUPLICATE_IMPORT:"
          "memory:main.dart:86:92:Duplicate import of 'hest'.:warning",
      "MessageKind.IMPORTED_HERE:"
          "memory:main.dart:0:22:'hest' is imported here.:info",
      "MessageKind.IMPORTED_HERE:"
          "memory:main.dart:23:46:'hest' is imported here.:info",
    ];
    Expect.listEquals(expected, diagnostics);
    Expect.isTrue(result.isSuccess);
  });
}

const Map MEMORY_SOURCE_FILES = const {
  'main.dart': """
import 'library.dart';
import 'exporter.dart';

main() {
  Fisk x = null;
  fisk();
  hest();
}
""",
  'library.dart': """
library lib;

class Fisk {
}

fisk() {}

hest() {}
""",
  'exporter.dart': """
library exporter;

export 'library.dart';

hest() {}
""",
};
