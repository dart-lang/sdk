// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart' show Diagnostic;
import 'package:compiler/src/dart2jslib.dart';
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

void main() {
  DiagnosticCollector collector = new DiagnosticCollector();
  Compiler compiler = compilerFor(
      MEMORY_SOURCE_FILES,
      diagnosticHandler: collector,
      options: ['--analyze-all']);
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    List<String> diagnostics = <String>[];
    collector.messages.forEach((DiagnosticMessage message) {
      if (message.kind == Diagnostic.VERBOSE_INFO) return;
      diagnostics.add(message.toString());
    });
    diagnostics.sort();
    var expected = [
        "memory:exporter.dart:43:47:'hest' is defined here.:info",
        "memory:library.dart:41:45:'hest' is defined here.:info",
        "memory:main.dart:0:22:'hest' is imported here.:info",
        "memory:main.dart:23:46:'hest' is imported here.:info",
        "memory:main.dart:86:92:Duplicate import of 'hest'.:warning",
    ];
    Expect.listEquals(expected, diagnostics);
    Expect.isFalse(compiler.compilationFailed);
  }));
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
