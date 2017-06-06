// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library test.kernel.closures.suite;

import 'dart:async' show Future;

import 'package:front_end/physical_file_system.dart' show PhysicalFileSystem;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, Step, TestDescription, runMe;

import 'package:front_end/src/fasta/testing/patched_sdk_location.dart'
    show computePatchedSdk;

import 'package:kernel/ast.dart' show Program;

import 'package:kernel/transformations/closure_conversion.dart'
    as closure_conversion;

import 'package:front_end/src/fasta/testing/kernel_chain.dart'
    show Print, MatchExpectation, WriteDill, ReadDill, Verify;

import 'package:front_end/src/fasta/ticker.dart' show Ticker;

import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;

import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;

import 'package:front_end/src/fasta/translate_uri.dart' show TranslateUri;

import 'package:front_end/src/fasta/errors.dart' show InputError;

import 'package:front_end/src/fasta/testing/patched_sdk_location.dart';

import 'package:kernel/kernel.dart' show loadProgramFromBinary;

import 'package:kernel/target/targets.dart' show TargetFlags;

import 'package:kernel/target/vm_fasta.dart' show VmFastaTarget;

const String STRONG_MODE = " strong mode ";

class ClosureConversionContext extends ChainContext {
  final bool strongMode;

  final TranslateUri uriTranslator;

  final List<Step> steps;

  ClosureConversionContext(
      this.strongMode, bool updateExpectations, this.uriTranslator)
      : steps = <Step>[
          const FastaCompile(),
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

  Future<Program> loadPlatform() async {
    Uri sdk = await computePatchedSdk();
    return loadProgramFromBinary(sdk.resolve('platform.dill').toFilePath());
  }

  static Future<ClosureConversionContext> create(
      Chain suite, Map<String, String> environment) async {
    Uri sdk = await computePatchedSdk();
    Uri packages = Uri.base.resolve(".packages");
    bool strongMode = environment.containsKey(STRONG_MODE);
    bool updateExpectations = environment["updateExpectations"] == "true";
    TranslateUri uriTranslator = await TranslateUri
        .parse(PhysicalFileSystem.instance, sdk, packages: packages);
    return new ClosureConversionContext(
        strongMode, updateExpectations, uriTranslator);
  }
}

Future<ClosureConversionContext> createContext(
    Chain suite, Map<String, String> environment) async {
  environment["updateExpectations"] =
      const String.fromEnvironment("updateExpectations");
  return ClosureConversionContext.create(suite, environment);
}

class FastaCompile
    extends Step<TestDescription, Program, ClosureConversionContext> {
  const FastaCompile();

  String get name => "fasta compilation";

  Future<Result<Program>> run(
      TestDescription description, ClosureConversionContext context) async {
    Program platform = await context.loadPlatform();
    Ticker ticker = new Ticker();
    DillTarget dillTarget = new DillTarget(ticker, context.uriTranslator,
        new VmFastaTarget(new TargetFlags(strongMode: context.strongMode)));
    platform.unbindCanonicalNames();
    dillTarget.loader.appendLibraries(platform);
    KernelTarget sourceTarget = new KernelTarget(
        PhysicalFileSystem.instance, dillTarget, context.uriTranslator);

    Program p;
    try {
      sourceTarget.read(description.uri);
      await dillTarget.buildOutlines();
      await sourceTarget.buildOutlines();
      p = await sourceTarget.buildProgram();
    } on InputError catch (e, s) {
      return fail(null, e.error, s);
    }
    return pass(p);
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
      program = closure_conversion.transformProgram(coreTypes, program);
      return pass(program);
    } catch (e, s) {
      return crash(e, s);
    }
  }
}

main(List<String> arguments) => runMe(arguments, createContext, "testing.json");
