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
import 'package:compiler/src/kernel/world_builder.dart';
import 'package:compiler/src/library_loader.dart'
    show ScriptLoader, LibraryLoaderTask;
import 'package:compiler/src/script.dart' show Script;
import 'package:compiler/src/apiimpl.dart' show CompilerImpl;
import "package:expect/expect.dart";
import 'package:path/path.dart' as path;

/// Run the dartk.dart script, and return the binary encoded results.
List<int> runDartk(Uri filename) {
  String basePath = path.fromUri(Uri.base);
  String dartkPath =
      path.normalize(path.join(basePath, 'tools/dartk_wrappers/dartk'));

  var args = [filename.path, '-fbin', '-ostdout'];
  ProcessResult result = Process.runSync(
      dartkPath, [filename.path, '-fbin', '-ostdout'],
      stdoutEncoding: null);
  Expect.equals(0, result.exitCode);
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
    Uri uri = Uri.base.resolve('tests/corelib/list_literal_test.dart');
    File entity = new File.fromUri(uri);
    DiagnosticCollector diagnostics = new DiagnosticCollector();
    OutputCollector output = new OutputCollector();
    Uri entryPoint = Uri.parse('memory:main.dill');
    List<int> kernelBinary = runDartk(entity.uri);

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

    KernelWorldBuilder worldBuilder = loader.worldBuilder;
    LibraryEntity library = worldBuilder.lookupLibrary(uri);
    Expect.isNotNull(library);
    ClassEntity clss = worldBuilder.lookupClass(library, 'ListLiteralTest');
    Expect.isNotNull(clss);
    var member = worldBuilder.lookupClassMember(clss, 'testMain');
    Expect.isNotNull(member);
  });
}
