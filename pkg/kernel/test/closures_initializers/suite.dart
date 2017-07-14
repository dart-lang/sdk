// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library test.kernel.closures.suite;

import 'dart:async' show Future;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, Step, runMe;

import 'package:kernel/ast.dart' show Program, Library;

import 'package:kernel/transformations/argument_extraction.dart'
    as argument_extraction;

import 'package:kernel/transformations/closure_conversion.dart'
    as closure_conversion;

import 'package:front_end/src/fasta/testing/kernel_chain.dart'
    show
        Compile,
        CompileContext,
        Print,
        MatchExpectation,
        WriteDill,
        ReadDill,
        Verify;

const String STRONG_MODE = " strong mode ";

class ClosureConversionContext extends ChainContext implements CompileContext {
  final bool strongMode;

  final List<Step> steps;

  ClosureConversionContext(this.strongMode, bool updateExpectations)
      : steps = <Step>[
          const Compile(),
          const Print(),
          const Verify(true),
          const ArgumentExtraction(),
          const Print(),
          const Verify(true),
          const ClosureConversion(),
          const Print(),
          const Verify(true),
          new MatchExpectation(".expect",
              updateExpectations: updateExpectations),
          const WriteDill(),
          const ReadDill(),
          // TODO(29143): add `Run` step when Vectors are added to VM.
        ];

  static Future<ClosureConversionContext> create(
      Chain suite, Map<String, String> environment) async {
    bool strongMode = environment.containsKey(STRONG_MODE);
    bool updateExpectations = environment["updateExpectations"] == "true";
    return new ClosureConversionContext(strongMode, updateExpectations);
  }
}

Future<ClosureConversionContext> createContext(
    Chain suite, Map<String, String> environment) async {
  environment["updateExpectations"] =
      const String.fromEnvironment("updateExpectations");
  return ClosureConversionContext.create(suite, environment);
}

class ArgumentExtraction
    extends Step<Program, Program, ClosureConversionContext> {
  const ArgumentExtraction();

  String get name => "argument extraction";

  Future<Result<Program>> run(
      Program program, ClosureConversionContext context) async {
    try {
      CoreTypes coreTypes = new CoreTypes(program);
      Library library = program.libraries
          .firstWhere((Library library) => library.importUri.scheme != "dart");
      argument_extraction.transformLibraries(coreTypes, <Library>[library]);
      return pass(program);
    } catch (e, s) {
      return crash(e, s);
    }
  }
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

main(List<String> arguments) => runMe(arguments, createContext, "testing.json");
