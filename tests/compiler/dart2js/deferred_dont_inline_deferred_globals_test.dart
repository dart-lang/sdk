// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the additional runtime type support is output to the right
// Files when using deferred loading.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_source_file_helper.dart';
import "dart:async";

import 'package:compiler/implementation/dart2jslib.dart'
       as dart2js;

class MemoryOutputSink extends EventSink<String> {
  StringBuffer mem = new StringBuffer();
  void add(String event) {
    mem.write(event);
  }
  void addError(String event, [StackTrace stackTrace]) {
    Expect.isTrue(false);
  }
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
    lookupLibrary(name) {
      return compiler.libraryLoader.lookupLibrary(Uri.parse(name));
    }

    var main = compiler.mainApp.find(dart2js.Compiler.MAIN);
    Expect.isNotNull(main, "Could not find 'main'");
    compiler.deferredLoadTask.onResolutionComplete(main);

    var outputUnitForElement = compiler.deferredLoadTask.outputUnitForElement;

    var lib1 = lookupLibrary("memory:lib1.dart");
    var foo1 = lib1.find("finalVar");
    var ou_lib1 = outputUnitForElement(foo1);

    String mainOutput = outputs["main.js"].mem.toString();
    String lib1Output = outputs["out_${ou_lib1.name}.part.js"].mem.toString();
    // Test that the deferred globals are not inlined into the main file.
    RegExp re1 = new RegExp(r"= .string1");
    RegExp re2 = new RegExp(r"= .string2");
    Expect.isTrue(re1.hasMatch(lib1Output));
    Expect.isTrue(re2.hasMatch(lib1Output));
    Expect.isFalse(re1.hasMatch(mainOutput));
    Expect.isFalse(re2.hasMatch(mainOutput));
  }));
}

// Make sure that deferred constants are not inlined into the main hunk.
const Map MEMORY_SOURCE_FILES = const {"main.dart": """
import "dart:async";

import 'lib1.dart' deferred as lib1;

void main() {
  lib1.loadLibrary().then((_) {
    print(lib1.finalVar);
    print(lib1.globalVar);
    lib1.globalVar = "foobar";
    print(lib1.globalVar);
  });
}
""", "lib1.dart": """
import "main.dart" as main;
final finalVar = "string1";
var globalVar = "string2";
"""};
