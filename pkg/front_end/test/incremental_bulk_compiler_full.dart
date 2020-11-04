// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart' show Expect;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions, DiagnosticMessage;

import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart'
    show IncrementalKernelGenerator;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/incremental_compiler.dart'
    show IncrementalCompiler;

import 'package:kernel/kernel.dart' show Component;

import 'package:kernel/text/ast_to_text.dart'
    show globalDebuggingNames, NameSystem;

import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, Step, TestDescription, runMe;

import 'incremental_utils.dart' as util;

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../testing.json");

Future<Context> createContext(
    Chain suite, Map<String, String> environment) async {
  return new Context();
}

class Context extends ChainContext {
  final List<Step> steps = const <Step>[
    const RunTest(),
  ];

  // Override special handling of negative tests.
  @override
  Result processTestResult(
      TestDescription description, Result result, bool last) {
    return result;
  }

  IncrementalCompiler compiler;
}

CompilerOptions getOptions() {
  final Uri sdkRoot = computePlatformBinariesLocation(forceBuildDir: true);
  var options = new CompilerOptions()
    ..sdkRoot = sdkRoot
    ..librariesSpecificationUri = Uri.base.resolve("sdk/lib/libraries.json")
    ..omitPlatform = true
    ..onDiagnostic = (DiagnosticMessage message) {
      // Ignored.
    };
  options.sdkSummary = sdkRoot.resolve("vm_platform_strong.dill");
  return options;
}

class RunTest extends Step<TestDescription, TestDescription, Context> {
  const RunTest();

  String get name => "run test";

  Future<Result<TestDescription>> run(
      TestDescription description, Context context) async {
    Uri uri = description.uri;

    // "One shot compile"
    bool oneShotFailed = false;
    List<int> oneShotSerialized;
    try {
      IncrementalCompiler compiler =
          new IncrementalKernelGenerator(getOptions(), uri);
      oneShotSerialized = util.postProcess(await compiler.computeDelta());
    } catch (e) {
      oneShotFailed = true;
    }

    // Bulk
    bool bulkFailed = false;
    List<int> bulkSerialized;
    try {
      globalDebuggingNames = new NameSystem();
      if (context.compiler == null) {
        context.compiler = new IncrementalKernelGenerator(getOptions(), uri);
      }
      Component bulkCompiledComponent = await context.compiler
          .computeDelta(entryPoints: [uri], fullComponent: true);
      bulkSerialized = util.postProcess(bulkCompiledComponent);
    } catch (e) {
      bulkFailed = true;
    }

    // Compile again - the serialized output should be the same.
    bool bulk2Failed = false;
    List<int> bulkSerialized2;
    try {
      globalDebuggingNames = new NameSystem();
      if (context.compiler == null) {
        context.compiler = new IncrementalKernelGenerator(getOptions(), uri);
      }
      Component bulkCompiledComponent = await context.compiler
          .computeDelta(entryPoints: [uri], fullComponent: true);
      bulkSerialized2 = util.postProcess(bulkCompiledComponent);
    } catch (e) {
      bulk2Failed = true;
    }

    if (bulkFailed || oneShotFailed) {
      if (bulkFailed != oneShotFailed) {
        throw "Bulk-compiler failed: $bulkFailed; "
            "one-shot failed: $oneShotFailed";
      }
    } else {
      checkIsEqual(oneShotSerialized, bulkSerialized);
    }

    if (bulkFailed || bulk2Failed) {
      if (bulkFailed != bulk2Failed) {
        throw "Bulk-compiler failed: $bulkFailed; "
            "second bulk-compile failed: $bulk2Failed";
      }
    } else {
      checkIsEqual(bulkSerialized, bulkSerialized2);
    }

    return pass(description);
  }

  void checkIsEqual(List<int> a, List<int> b) {
    int length = a.length;
    if (b.length < length) {
      length = b.length;
    }
    for (int i = 0; i < length; ++i) {
      if (a[i] != b[i]) {
        Expect.fail("Data differs at byte ${i + 1}.");
      }
    }
    Expect.equals(a.length, b.length);
  }
}
