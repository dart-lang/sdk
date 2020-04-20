// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import '../helpers/memory_compiler.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/apiimpl.dart' show CompilerImpl;
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/elements/entities.dart'
    show LibraryEntity, ClassEntity;
import 'package:compiler/src/kernel/dart2js_target.dart';
import 'package:compiler/src/kernel/loader.dart';
import 'package:expect/expect.dart';
import 'package:front_end/src/api_prototype/front_end.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:front_end/src/fasta/kernel/utils.dart' show serializeComponent;
import 'package:kernel/target/targets.dart' show TargetFlags;

/// Test that the compiler can successfully read in .dill kernel files rather
/// than just string source files.
main() {
  asyncTest(() async {
    String filename = 'tests/corelib_2/list_literal_test.dart';
    Uri uri = Uri.base.resolve(filename);
    DiagnosticCollector diagnostics = new DiagnosticCollector();
    OutputCollector output = new OutputCollector();
    Uri entryPoint = Uri.parse('memory:main.dill');

    var options = new CompilerOptions()
      ..target = new Dart2jsTarget("dart2js", new TargetFlags())
      ..packagesFileUri = Uri.base.resolve('.packages')
      ..additionalDills = <Uri>[
        computePlatformBinariesLocation().resolve("dart2js_platform.dill"),
      ]
      ..setExitCodeOnProblem = true
      ..verify = true;

    List<int> kernelBinary =
        serializeComponent((await kernelForProgram(uri, options)).component);
    CompilerImpl compiler = compilerFor(
        entryPoint: entryPoint,
        memorySourceFiles: {'main.dill': kernelBinary},
        diagnosticHandler: diagnostics,
        outputProvider: output);
    await compiler.setupSdk();
    KernelResult result = await compiler.kernelLoader.load(entryPoint);
    compiler.frontendStrategy.registerLoadedLibraries(result);

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
