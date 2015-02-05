// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the additional runtime type support is output to the right
// Files when using deferred loading.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'memory_source_file_helper.dart';
import 'output_collector.dart';

void main() {
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  var provider = new MemorySourceFileProvider(MEMORY_SOURCE_FILES);
  var handler = new FormattingDiagnosticHandler(provider);

  OutputCollector collector = new OutputCollector();

  Compiler compiler = new Compiler(provider.readStringFromUri,
      collector,
                                   handler.diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   [],
                                   {});
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    String mainOutput = collector.getOutput('', 'js');
    String deferredOutput =  collector.getOutput('out_1', 'part.js');
    String isPrefix = compiler.backend.namer.operatorIsPrefix;
    Expect.isTrue(deferredOutput.contains('${isPrefix}A: 1'),
        "Deferred output doesn't contain '${isPrefix}A: 1':\n"
        "$deferredOutput");
    Expect.isFalse(mainOutput.contains('${isPrefix}A: 1'));
  }));
}

// We force additional runtime type support to be output for A by instantiating
// it with a type argument, and testing for the type. The extra support should
// go to the deferred hunk.
const Map MEMORY_SOURCE_FILES = const {"main.dart": """
import 'lib.dart' deferred as lib show f, A, instance;

void main() {
  lib.loadLibrary().then((_) {
    print(lib.f(lib.instance));
  });
}
""", "lib.dart": """
class A<T> {}

class B<T> implements A<T> {}

B<B> instance = new B<B>();

bool f (Object o) {
  return o is A<A>;
}
""",};
