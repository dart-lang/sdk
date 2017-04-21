// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.testing.suite;

import 'dart:async' show Future;

import 'dart:convert' show JSON;

import 'package:analyzer/src/generated/sdk.dart' show DartSdk;

import 'package:kernel/ast.dart' show Library, Program;

import 'package:analyzer/src/kernel/loader.dart' show DartLoader;

import 'package:kernel/target/targets.dart' show Target, TargetFlags, getTarget;

import 'package:testing/testing.dart'
    show Chain, ExpectationSet, Result, Step, TestDescription;

import '../errors.dart' show InputError;

import 'kernel_chain.dart'
    show MatchExpectation, Print, Run, Verify, TestContext, WriteDill;

import '../ticker.dart' show Ticker;

import '../translate_uri.dart' show TranslateUri;

import '../analyzer/analyzer_target.dart' show AnalyzerTarget;

import '../kernel/kernel_target.dart' show KernelTarget;

import '../dill/dill_target.dart' show DillTarget;

export 'kernel_chain.dart' show TestContext;

export 'package:testing/testing.dart' show Chain, runMe;

const String ENABLE_FULL_COMPILE = " full compile ";

const String AST_KIND_INDEX = " AST kind index ";

const String EXPECTATIONS = '''
[
  {
    "name": "VerificationError",
    "group": "Fail"
  }
]
''';

String shortenAstKindName(AstKind astKind) {
  switch (astKind) {
    case AstKind.Analyzer:
      return "dartk";
    case AstKind.Kernel:
      return "direct";
  }
  throw "Unknown AST kind: $astKind";
}

enum AstKind {
  Analyzer,
  Kernel,
}

class FastaContext extends TestContext {
  final TranslateUri uriTranslator;

  final List<Step> steps;

  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(JSON.decode(EXPECTATIONS));

  Future<Program> platform;

  FastaContext(
      Uri sdk,
      Uri vm,
      Uri packages,
      bool strongMode,
      DartSdk dartSdk,
      bool updateExpectations,
      this.uriTranslator,
      bool fullCompile,
      AstKind astKind)
      : steps = <Step>[
          new Outline(fullCompile, astKind),
          const Print(),
          new Verify(fullCompile),
          new MatchExpectation(
              fullCompile
                  ? ".${shortenAstKindName(astKind)}.expect"
                  : ".outline.expect",
              updateExpectations: updateExpectations)
        ],
        super(sdk, vm, packages, strongMode, dartSdk) {
    if (fullCompile) {
      steps.add(const WriteDill());
      steps.add(const Run());
    }
  }

  Future<Program> createPlatform() {
    return platform ??= new Future<Program>(() async {
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

  static Future<FastaContext> create(
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
      String astKindString = environment[AST_KIND_INDEX];
      AstKind astKind = astKindString == null
          ? null
          : AstKind.values[int.parse(astKindString)];
      return new FastaContext(
          sdk,
          vm,
          packages,
          strongMode,
          dartSdk,
          updateExpectations,
          uriTranslator,
          environment.containsKey(ENABLE_FULL_COMPILE),
          astKind);
    });
  }
}

class Outline extends Step<TestDescription, Program, FastaContext> {
  final bool fullCompile;

  final AstKind astKind;

  const Outline(this.fullCompile, this.astKind);

  String get name {
    return fullCompile ? "${astKind} compile" : "outline";
  }

  bool get isCompiler => fullCompile;

  Future<Result<Program>> run(
      TestDescription description, FastaContext context) async {
    Program platform = await context.createPlatform();
    Ticker ticker = new Ticker();
    DillTarget dillTarget = new DillTarget(ticker, context.uriTranslator);
    dillTarget.loader
      ..input = Uri.parse("org.dartlang:platform") // Make up a name.
      ..setProgram(platform);
    KernelTarget sourceTarget = astKind == AstKind.Analyzer
        ? new AnalyzerTarget(dillTarget, context.uriTranslator)
        : new KernelTarget(dillTarget, context.uriTranslator);

    Program p;
    try {
      sourceTarget.read(description.uri);
      await dillTarget.writeOutline(null);
      p = await sourceTarget.writeOutline(null);
      if (fullCompile) {
        p = await sourceTarget.writeProgram(null);
      }
    } on InputError catch (e, s) {
      return fail(null, e.error, s);
    }
    return pass(p);
  }
}
