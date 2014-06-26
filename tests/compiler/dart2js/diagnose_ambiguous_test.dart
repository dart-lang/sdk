// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_source_file_helper.dart';

import 'package:compiler/compiler.dart'
       show Diagnostic;

main() {
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  var provider = new MemorySourceFileProvider(MEMORY_SOURCE_FILES);
  var diagnostics = [];
  void diagnosticHandler(Uri uri, int begin, int end,
                         String message, Diagnostic kind) {
    if (kind == Diagnostic.VERBOSE_INFO) {
      return;
    }
    diagnostics.add('$uri:$begin:$end:$message:$kind');
  }

  Compiler compiler = new Compiler(provider.readStringFromUri,
                                   (name, extension) => null,
                                   diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   ['--analyze-only'],
                                   {});
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    diagnostics.sort();
    var expected = [
        "memory:exporter.dart:43:47:'hest' is defined here.:info",
        "memory:library.dart:41:45:'hest' is defined here.:info",
        "memory:main.dart:0:22:'hest' is imported here.:info",
        "memory:main.dart:23:46:'hest' is imported here.:info",
        "memory:main.dart:86:90:Duplicate import of 'hest'.:error"
    ];
    Expect.listEquals(expected, diagnostics);
    Expect.isTrue(compiler.compilationFailed);
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
