// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library test.kernel.closures.suite;

import 'dart:async' show Future;

import 'package:analyzer/src/generated/sdk.dart' show DartSdk;

import 'package:analyzer/src/kernel/loader.dart' show DartLoader;

import 'package:testing/testing.dart'
    show Chain, Result, Step, TestDescription, runMe;

import 'package:kernel/ast.dart' show Program, Library;

import 'package:kernel/transformations/closure_conversion.dart'
    as closure_conversion;

import 'package:kernel/target/targets.dart' show Target, TargetFlags, getTarget;

import 'package:front_end/src/fasta/testing/kernel_chain.dart'
    show TestContext, Print, MatchExpectation, WriteDill, ReadDill, Verify;

import 'package:front_end/src/fasta/ticker.dart' show Ticker;

import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;

import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;

import 'package:front_end/src/fasta/translate_uri.dart' show TranslateUri;

import 'package:front_end/src/fasta/errors.dart' show InputError;

class ClosureConversionContext extends TestContext {
  final TranslateUri uriTranslator;

  final List<Step> steps;

  Future<Program> platform;

  ClosureConversionContext(Uri sdk, Uri vm, Uri packages, bool strongMode,
      DartSdk dartSdk, bool updateExpectations, this.uriTranslator)
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
          // TODO(29143): uncomment this when Vectors are added to VM.
          //const Run(),
        ],
        super(sdk, vm, packages, strongMode, dartSdk);

  Future<Program> createPlatform() {
    return new Future<Program>(() async {
      DartLoader loader = await createLoader();
      Target target =
          getTarget("vm", new TargetFlags(strongMode: options.strongMode));
      loader.loadProgram(Uri.base.resolve("pkg/fasta/test/platform.dart"),
          target: target);
      var program = loader.program;
      if (loader.errors.isNotEmpty) {
        throw loader.errors.join("\n");
      }
      Library mainLibrary = program.mainMethod.enclosingLibrary;
      program.uriToSource.remove(mainLibrary.fileUri);
      program = new Program(
          program.libraries.where((Library l) => l != mainLibrary).toList(),
          program.uriToSource);
      target.performModularTransformations(program);
      target.performGlobalTransformations(program);
      return program;
    });
  }

  static Future<ClosureConversionContext> create(
      Chain suite, Map<String, String> environment) async {
    return TestContext.create(suite, environment, (Chain suite,
        Map<String, String> environment,
        Uri sdk,
        Uri vm,
        Uri packages,
        bool strongMode,
        DartSdk dartSdk,
        bool updateExpectations) async {
      TranslateUri uriTranslator = await TranslateUri.parse(packages);
      return new ClosureConversionContext(sdk, vm, packages, strongMode,
          dartSdk, updateExpectations, uriTranslator);
    });
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
    Program platform = await context.createPlatform();
    Ticker ticker = new Ticker();
    DillTarget dillTarget = new DillTarget(ticker, context.uriTranslator);
    dillTarget.loader
      ..input = Uri.parse("org.dartlang:platform") // Make up a name.
      ..setProgram(platform);
    KernelTarget sourceTarget =
        new KernelTarget(dillTarget, context.uriTranslator, false);

    Program p;
    try {
      sourceTarget.read(description.uri);
      await dillTarget.writeOutline(null);
      await sourceTarget.writeOutline(null);
      p = await sourceTarget.writeProgram(null);
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
      program = closure_conversion.transformProgram(program);
      return pass(program);
    } catch (e, s) {
      return crash(e, s);
    }
  }
}

main(List<String> arguments) => runMe(arguments, createContext, "testing.json");
