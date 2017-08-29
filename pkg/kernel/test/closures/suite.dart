// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library test.kernel.closures.suite;

import 'dart:io' show File;

import 'dart:async' show Future;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, Step, runMe, StdioProcess;

import 'package:kernel/ast.dart' show Program, Library;

import 'package:kernel/target/targets.dart' show Target;

import 'package:front_end/src/fasta/testing/kernel_chain.dart'
    show
        Print,
        MatchExpectation,
        WriteDill,
        ReadDill,
        Verify,
        Compile,
        CompileContext;

import 'package:kernel/transformations/closure_conversion.dart'
    as closure_conversion;

import 'package:front_end/src/fasta/testing/patched_sdk_location.dart'
    show computePatchedSdk, computeDartVm;

const String STRONG_MODE = " strong mode ";

class ClosureConversionContext extends ChainContext implements CompileContext {
  final bool strongMode;
  Target get target => null;

  final List<Step> steps;

  Program platform;

  ClosureConversionContext(this.strongMode, bool updateExpectations)
      : steps = <Step>[
          const Compile(),
          const Print(),
          const Verify(true),
          const ClosureConversion(),
          const Print(),
          const Verify(true),
          new MatchExpectation(".expect",
              updateExpectations: updateExpectations),
          const WriteDill(),
          const ReadDill(),
          const Run(),
        ];

  static Future<ClosureConversionContext> create(
      Chain suite, Map<String, String> environment, bool strongMode) async {
    bool updateExpectations = environment["updateExpectations"] == "true";
    return new ClosureConversionContext(strongMode, updateExpectations);
  }
}

Future<ClosureConversionContext> createContext(
    Chain suite, Map<String, String> environment) async {
  bool strongMode = environment.containsKey(STRONG_MODE);
  environment["updateExpectations"] =
      const String.fromEnvironment("updateExpectations");
  return ClosureConversionContext.create(suite, environment, strongMode);
}

class ClosureConversion
    extends Step<Program, Program, ClosureConversionContext> {
  const ClosureConversion();

  String get name => "closure conversion";

  Future<Result<Program>> run(
      Program program, ClosureConversionContext testContext) async {
    try {
      CoreTypes coreTypes = new CoreTypes(program);
      Library library = program.libraries
          .firstWhere((Library library) => library.importUri.scheme != "dart");
      closure_conversion.transformLibraries(coreTypes, <Library>[library]);
      return pass(program);
    } catch (e, s) {
      return crash(e, s);
    }
  }
}

class Run extends Step<Uri, int, ClosureConversionContext> {
  const Run();

  String get name => "run";

  Future<Result<int>> run(Uri uri, ClosureConversionContext context) async {
    final File generated = new File.fromUri(uri);
    try {
      Uri sdk = await computePatchedSdk();
      Uri vm = computeDartVm(sdk);
      final StdioProcess process = await StdioProcess.run(vm.toFilePath(), [
        "--reify",
        "--reify_generic_functions",
        "-c",
        generated.path,
        "Hello, World!"
      ]);
      print(process.output);
      return process.toResult();
    } finally {
      generated.parent.delete(recursive: true);
    }
  }
}

main(List<String> arguments) => runMe(arguments, createContext, "testing.json");
