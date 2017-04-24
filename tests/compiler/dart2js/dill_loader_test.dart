// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'memory_compiler.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/diagnostics/spannable.dart' show Spannable;
import 'package:compiler/src/elements/entities.dart'
    show LibraryEntity, ClassEntity;
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/library_loader.dart'
    show ScriptLoader, LibraryLoaderTask;
import 'package:compiler/src/script.dart' show Script;
import 'package:compiler/src/apiimpl.dart' show CompilerImpl;
import "package:expect/expect.dart";
import 'package:path/path.dart' as path;

final String dartkExecutable = Platform.isWindows
    ? 'tools/dartk_wrappers/dartk.bat'
    : 'tools/dartk_wrappers/dartk';

/// Run the dartk.dart script, and return the binary encoded results.
List<int> runDartk(String filename) {
  String basePath = path.fromUri(Uri.base);
  String dartkPath = path.normalize(path.join(basePath, dartkExecutable));

  var args = [filename, '-fbin', '-ostdout'];
  ProcessResult result = Process.runSync(dartkPath, args, stdoutEncoding: null);
  Expect.equals(0, result.exitCode, result.stderr);
  return result.stdout;
}

class TestScriptLoader implements ScriptLoader {
  CompilerImpl compiler;
  TestScriptLoader(this.compiler);

  Future<Script> readScript(Uri uri, [Spannable spannable]) =>
      compiler.readScript(uri, spannable);
}

/// Test that the compiler can successfully read in .dill kernel files rather
/// than just string source files.
main() {
  asyncTest(() async {
    String filename = 'tests/corelib/list_literal_test.dart';
    Uri uri = Uri.base.resolve(filename);
    DiagnosticCollector diagnostics = new DiagnosticCollector();
    OutputCollector output = new OutputCollector();
    Uri entryPoint = Uri.parse('memory:main.dill');
    List<int> kernelBinary = runDartk(filename);

    CompilerImpl compiler = compilerFor(
        entryPoint: entryPoint,
        memorySourceFiles: {'main.dill': kernelBinary},
        diagnosticHandler: diagnostics,
        outputProvider: output,
        options: ['--read-dill']);
    await compiler.setupSdk();
    dynamic loader = new LibraryLoaderTask(
        true,
        compiler.resolvedUriTranslator,
        new TestScriptLoader(compiler),
        null,
        null,
        null,
        null,
        null,
        compiler.reporter,
        compiler.measurer);

    await loader.loadLibrary(entryPoint);

    Expect.equals(0, diagnostics.errors.length);
    Expect.equals(0, diagnostics.warnings.length);

    KernelToElementMap elementMap = loader.elementMap;
    LibraryEntity library = elementMap.lookupLibrary(uri);
    Expect.isNotNull(library);
    ClassEntity clss = elementMap.lookupClass(library, 'ListLiteralTest');
    Expect.isNotNull(clss);
    var member = elementMap.lookupClassMember(clss, 'testMain');
    Expect.isNotNull(member);
  });
}
