// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'memory_compiler.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/diagnostics/spannable.dart' show Spannable;
import 'package:compiler/src/elements/entities.dart'
    show LibraryEntity, ClassEntity;
import 'package:compiler/src/io/source_file.dart' show Binary;
import 'package:compiler/src/library_loader.dart' show ScriptLoader;
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

  Future<Binary> readBinary(Uri uri, [Spannable spannable]) =>
      compiler.readBinary(uri, spannable);
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
        options: [Flags.loadFromDill]);
    await compiler.setupSdk();
    await compiler.libraryLoader.loadLibrary(entryPoint);

    Expect.equals(0, diagnostics.errors.length);
    Expect.equals(0, diagnostics.warnings.length);

    ElementEnvironment environment =
        compiler.frontendStrategy.elementEnvironment;
    LibraryEntity library = environment.lookupLibrary(uri);
    Expect.isNotNull(library);
    ClassEntity clss = environment.lookupClass(library, 'ListLiteralTest');
    Expect.isNotNull(clss);
    var member = environment.lookupClassMember(clss, 'testMain');
    Expect.isNotNull(member);
  });
}
