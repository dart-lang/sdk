// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the additional runtime type support is output to the right
// Files when using deferred loading.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_source_file_helper.dart';
import "dart:async";

import 'package:compiler/src/dart2jslib.dart'
       as dart2js;

class MemoryOutputSink<T> extends EventSink<T> {
  List<T> mem = new List<T>();
  void add(T event) {
    mem.add(event);
  }
  void addError(T event, [StackTrace stackTrace]) {}
  void close() {}
}

void main() {
  Uri script = currentDirectory.resolveUri(Platform.script);
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  var provider = new MemorySourceFileProvider(MEMORY_SOURCE_FILES);
  var handler = new FormattingDiagnosticHandler(provider);

  Map<String, MemoryOutputSink> outputs = new Map<String, MemoryOutputSink>();

  MemoryOutputSink outputSaver(name, extension) {
    if (name == '') {
      name = 'main';
      extension ='js';
    }
    return outputs.putIfAbsent("$name.$extension", () {
     return new MemoryOutputSink();
    });
  }

  Compiler compiler = new Compiler(provider.readStringFromUri,
                                   outputSaver,
                                   handler.diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   [],
                                   {});
  asyncTest(() => compiler.run(Uri.parse('memory:main.dart')).then((_) {
    String mainOutput = outputs['main.js'].mem[0];
    String deferredOutput = outputs['out_1.part.js'].mem[0];
    RegExp re = new RegExp(r"\n  _ = .\.A;\n  _.\$isA = TRUE;");
    print(deferredOutput);
    Expect.isTrue(re.hasMatch(deferredOutput));
    Expect.isFalse(re.hasMatch(mainOutput));
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

A<A> instance = new A<A>();

bool f (Object o) {
  return o is A<A>;
}
""",};
