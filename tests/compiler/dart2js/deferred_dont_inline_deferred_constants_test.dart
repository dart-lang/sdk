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
    String mainOutput = outputs['main.js'].mem.toString();
    String lib1Output = outputs['out_lib1.part.js'].mem.toString();
    String lib2Output = outputs['out_lib2.part.js'].mem.toString();
    String lib12Output = outputs['out_lib1_lib2.part.js'].mem.toString();
    // Test that the deferred constants are not inlined into the main file.
    RegExp re1 = new RegExp(r"= .string1");
    RegExp re2 = new RegExp(r"= .string2");
    RegExp re3 = new RegExp(r"= 1010");
    Expect.isTrue(re1.hasMatch(lib1Output));
    Expect.isTrue(re2.hasMatch(lib1Output));
    Expect.isTrue(re3.hasMatch(lib1Output));
    Expect.isFalse(re1.hasMatch(mainOutput));
    Expect.isFalse(re2.hasMatch(mainOutput));
    Expect.isFalse(re3.hasMatch(mainOutput));
    // Test that the non-deferred constant is inlined.
    Expect.isTrue(new RegExp(r"print\(.string3.\)").hasMatch(mainOutput));
    Expect.isFalse(new RegExp(r"= .string3").hasMatch(mainOutput));
    Expect.isTrue(new RegExp(r"print\(.string4.\)").hasMatch(mainOutput));

    // C(1) is shared between main, lib1 and lib2. Test that lib1 and lib2 each
    // has a reference to it. It is defined in the main output file.
    Expect.isTrue(new RegExp(r"C.C_1 =").hasMatch(mainOutput));
    Expect.isFalse(new RegExp(r"= C.C_1").hasMatch(mainOutput));

    Expect.isTrue(new RegExp(r"= C.C_1").hasMatch(lib1Output));
    Expect.isTrue(new RegExp(r"= C.C_1").hasMatch(lib2Output));

    // C(2) is shared between lib1 and lib2, each of them has their own
    // reference to it.
    Expect.isFalse(new RegExp(r"= C.C_2").hasMatch(mainOutput));

    Expect.isTrue(new RegExp(r"= C.C_2").hasMatch(lib1Output));
    Expect.isTrue(new RegExp(r"= C.C_2").hasMatch(lib2Output));
    Expect.isTrue(new RegExp(r"C.C_2 =").hasMatch(lib12Output));

    // "string4" is shared between lib1 and lib2, but it can be inlined.
    Expect.isTrue(new RegExp(r"= .string4").hasMatch(lib1Output));
    Expect.isTrue(new RegExp(r"= .string4").hasMatch(lib2Output));
    Expect.isFalse(new RegExp(r"= .string4").hasMatch(lib12Output));
  }));
}

// Make sure that deferred constants are not inlined into the main hunk.
const Map MEMORY_SOURCE_FILES = const {"main.dart": """
import "dart:async";

import 'lib1.dart' deferred as lib1;
import 'lib2.dart' deferred as lib2;

const c = "string3";

class C {
  final p;
  const C(this.p);
}

void main() {
  lib1.loadLibrary().then((_) {
    lib2.loadLibrary().then((_) {
      print(lib1.C1);
      print(lib1.C2);
      print(lib1.C.C3);
      print(c);
      print(lib1.C4);
      print(lib2.C4);
      print(lib1.C5);
      print(lib2.C5);
      print(lib1.C6);
      print(lib2.C6);
      print("string4");
      print(const C(1));
    });
  });
}
""", "lib1.dart": """
import "main.dart" as main;
const C1 = "string1";
const C2 = 1010;
class C {
  static const C3 = "string2";
}
const C4 = "string4";
const C5 = const main.C(1);
const C6 = const main.C(2);
""", "lib2.dart": """
import "main.dart" as main;
const C4 = "string4";
const C5 = const main.C(1);
const C6 = const main.C(2);
"""};
