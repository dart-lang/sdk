// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.testing.suite;

import 'dart:async' show
    Future;

import 'dart:convert' show
    JSON;

import 'package:analyzer/src/generated/sdk.dart' show
    DartSdk;

import 'package:kernel/ast.dart' show
    Library,
    Program;

import 'package:kernel/analyzer/loader.dart' show
    DartLoader;

import 'package:kernel/target/targets.dart' show
    Target,
    TargetFlags,
    getTarget;

import 'package:testing/testing.dart' show
    Chain,
    ExpectationSet,
    Result,
    Step,
    TestDescription;

import '../errors.dart' show
    InputError;

import 'kernel_chain.dart' show
    MatchExpectation,
    Print,
    Run,
    Verify,
    TestContext,
    WriteDill;

import '../ticker.dart' show
    Ticker;

import '../translate_uri.dart' show
    TranslateUri;

import '../kernel/kernel_target.dart' show
    KernelSourceTarget;

import '../dill/dill_target.dart' show
    DillTarget;

import '../ast_kind.dart' show
    AstKind;

export 'kernel_chain.dart' show
    TestContext;

export 'package:testing/testing.dart' show
    Chain,
    runMe;

export '../ast_kind.dart' show
    AstKind;

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
    case AstKind.Analyzer: return "dartk";
    case AstKind.Kernel: return "direct";
  }
  throw "Unknown AST kind: $astKind";
}

class FeContext extends TestContext {
  final TranslateUri uriTranslator;

  final List<Step> steps;

  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(JSON.decode(EXPECTATIONS));

  Future<Program> platform;

  FeContext(String sdk, Uri vm, Uri packages, bool strongMode,
      DartSdk dartSdk, bool updateExpectations, this.uriTranslator,
      bool fullCompile, AstKind astKind)
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
      Target target = getTarget(
          "vm", new TargetFlags(strongMode: options.strongMode));
      Program program = loader.loadProgram(
          Uri.base.resolve("pkg/fasta/test/platform.dart"), target: target);
      target.transformProgram(program);
      if (loader.errors.isNotEmpty) {
        throw loader.errors.join("\n");
      }
      Library mainLibrary = program.mainMethod.enclosingLibrary;
      program.uriToLineStarts.remove(mainLibrary.fileUri);
      return new Program(
          program.libraries.where((Library l) => l != mainLibrary).toList(),
          program.uriToLineStarts);
    });
  }

  static Future<FeContext> create(Chain suite, Map<String, String> environment,
      String sdk, Uri vm, Uri packages, bool strongMode, DartSdk dartSdk,
      bool updateExpectations) async {
    TranslateUri uriTranslator = await TranslateUri.parse(packages);
    String astKindString = environment[AST_KIND_INDEX];
    AstKind astKind = astKindString == null
        ? null : AstKind.values[int.parse(astKindString)];
    return new FeContext(
        sdk, vm, packages, strongMode, dartSdk, updateExpectations,
        uriTranslator, environment.containsKey(ENABLE_FULL_COMPILE), astKind);
  }
}

class Outline extends Step<TestDescription, Program, FeContext> {
  final bool fullCompile;

  final AstKind astKind;

  const Outline(this.fullCompile, this.astKind);

  String get name {
    return fullCompile ? "${shortenAstKindName(astKind)} compile" : "outline";
  }

  bool get isCompiler => fullCompile;

  Future<Result<Program>> run(
      TestDescription description, FeContext context) async {
    Program platform = await context.createPlatform();
    Ticker ticker = new Ticker();
    DillTarget dillTarget = new DillTarget(ticker, context.uriTranslator);
    dillTarget.loader
        ..input = Uri.parse("org.dartlang:platform") // Make up a name.
        ..setProgram(platform);
    KernelSourceTarget sourceTarget =
        new KernelSourceTarget(dillTarget, context.uriTranslator);
    Program p;
    try {
      sourceTarget.read(description.uri);
      await dillTarget.writeOutline(null);
      p = await sourceTarget.writeOutline(null);
      if (fullCompile) {
        p = await sourceTarget.writeProgram(null, astKind);
      }
    } on InputError catch (e, s) {
      return fail(null, e.error, s);
    }
    return pass(p);
  }
}
