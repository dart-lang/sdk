// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.testing.suite;

import 'dart:async' show Future;

import 'dart:io' show File;

import 'dart:convert' show JSON;

import 'package:front_end/physical_file_system.dart' show PhysicalFileSystem;

import 'package:front_end/src/fasta/testing/validating_instrumentation.dart'
    show ValidatingInstrumentation;

import 'package:front_end/src/fasta/testing/patched_sdk_location.dart'
    show computeDartVm, computePatchedSdk;

import 'package:kernel/ast.dart' show Program;

import 'package:testing/testing.dart'
    show
        Chain,
        ChainContext,
        ExpectationSet,
        Result,
        Step,
        TestDescription,
        StdioProcess;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/errors.dart' show InputError;

import 'package:front_end/src/fasta/testing/kernel_chain.dart'
    show MatchExpectation, Print, Verify, WriteDill;

import 'package:front_end/src/fasta/ticker.dart' show Ticker;

import 'package:front_end/src/fasta/translate_uri.dart' show TranslateUri;

import 'package:analyzer/src/fasta/analyzer_target.dart' show AnalyzerTarget;

import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;

import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;

import 'package:kernel/kernel.dart' show loadProgramFromBytes;

import 'package:kernel/target/targets.dart' show TargetFlags;

import 'package:kernel/target/vm_fasta.dart' show VmFastaTarget;

export 'package:testing/testing.dart' show Chain, runMe;

const String STRONG_MODE = " strong mode ";

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

String shortenAstKindName(AstKind astKind, bool strongMode) {
  switch (astKind) {
    case AstKind.Analyzer:
      return strongMode ? "dartk-strong" : "dartk";
    case AstKind.Kernel:
      return strongMode ? "strong" : "direct";
  }
  throw "Unknown AST kind: $astKind";
}

enum AstKind {
  Analyzer,
  Kernel,
}

class FastaContext extends ChainContext {
  final TranslateUri uriTranslator;
  final List<Step> steps;
  final Uri vm;
  Uri sdk;
  Uri platformUri;
  Uri outlineUri;
  List<int> outlineBytes;

  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(JSON.decode(EXPECTATIONS));

  FastaContext(
      this.vm,
      bool strongMode,
      bool updateExpectations,
      bool updateComments,
      bool skipVm,
      this.uriTranslator,
      bool fullCompile,
      AstKind astKind)
      : steps = <Step>[
          new Outline(fullCompile, astKind, strongMode,
              updateComments: updateComments),
          const Print(),
          new Verify(fullCompile),
          new MatchExpectation(
              fullCompile
                  ? ".${shortenAstKindName(astKind, strongMode)}.expect"
                  : ".outline.expect",
              updateExpectations: updateExpectations)
        ] {
    if (fullCompile && !skipVm) {
      steps.add(const WriteDill());
      steps.add(const Run());
    }
  }

  Future ensurePlatformUris() async {
    if (sdk == null) {
      sdk = await computePatchedSdk();
      platformUri = sdk.resolve('platform.dill');
      outlineUri = sdk.resolve('outline.dill');
    }
  }

  Future<Program> loadPlatformOutline() async {
    if (outlineBytes == null) {
      await ensurePlatformUris();
      outlineBytes = new File.fromUri(outlineUri).readAsBytesSync();
    }
    // Note: we rebuild the platform outline on every test because the compiler
    // currently mutates the in-memory representation of the program without
    // cloning it.
    // TODO(sigmund): investigate alternatives to this approach.
    return loadProgramFromBytes(outlineBytes);
  }

  static Future<FastaContext> create(
      Chain suite, Map<String, String> environment) async {
    Uri sdk = await computePatchedSdk();
    Uri vm = computeDartVm(sdk);
    Uri packages = Uri.base.resolve(".packages");
    TranslateUri uriTranslator = await TranslateUri
        .parse(PhysicalFileSystem.instance, sdk, packages: packages);
    bool strongMode = environment.containsKey(STRONG_MODE);
    bool updateExpectations = environment["updateExpectations"] == "true";
    bool updateComments = environment["updateComments"] == "true";
    bool skipVm = environment["skipVm"] == "true";
    String astKindString = environment[AST_KIND_INDEX];
    AstKind astKind =
        astKindString == null ? null : AstKind.values[int.parse(astKindString)];
    return new FastaContext(
        vm,
        strongMode,
        updateExpectations,
        updateComments,
        skipVm,
        uriTranslator,
        environment.containsKey(ENABLE_FULL_COMPILE),
        astKind);
  }
}

class Run extends Step<Uri, int, FastaContext> {
  const Run();

  String get name => "run";

  bool get isAsync => true;

  bool get isRuntime => true;

  Future<Result<int>> run(Uri uri, FastaContext context) async {
    File generated = new File.fromUri(uri);
    StdioProcess process;
    try {
      await context.ensurePlatformUris();
      var platformDill = context.platformUri.toFilePath();
      var args = ['--platform=$platformDill', generated.path, "Hello, World!"];
      process = await StdioProcess.run(context.vm.toFilePath(), args);
      print(process.output);
    } finally {
      generated.parent.delete(recursive: true);
    }
    return process.toResult();
  }
}

class Outline extends Step<TestDescription, Program, FastaContext> {
  final bool fullCompile;

  final AstKind astKind;

  final bool strongMode;

  const Outline(this.fullCompile, this.astKind, this.strongMode,
      {this.updateComments: false});

  final bool updateComments;

  String get name {
    return fullCompile ? "${astKind} compile" : "outline";
  }

  bool get isCompiler => fullCompile;

  Future<Result<Program>> run(
      TestDescription description, FastaContext context) async {
    // Disable colors to ensure that expectation files are the same across
    // platforms and independent of stdin/stderr.
    CompilerContext.current.disableColors();
    Program platformOutline = await context.loadPlatformOutline();
    Ticker ticker = new Ticker();
    DillTarget dillTarget = new DillTarget(ticker, context.uriTranslator,
        new VmFastaTarget(new TargetFlags(strongMode: strongMode)));
    platformOutline.unbindCanonicalNames();
    dillTarget.loader.appendLibraries(platformOutline);
    // We create a new URI translator to avoid reading plaform libraries from
    // file system.
    TranslateUri uriTranslator = new TranslateUri(
        context.uriTranslator.packages,
        const <String, Uri>{},
        const <String, List<Uri>>{});
    KernelTarget sourceTarget = astKind == AstKind.Analyzer
        ? new AnalyzerTarget(dillTarget, uriTranslator, strongMode)
        : new KernelTarget(
            PhysicalFileSystem.instance, dillTarget, uriTranslator);

    Program p;
    try {
      sourceTarget.read(description.uri);
      await dillTarget.buildOutlines();
      ValidatingInstrumentation instrumentation;
      if (strongMode) {
        instrumentation = new ValidatingInstrumentation();
        await instrumentation.loadExpectations(description.uri);
        sourceTarget.loader.instrumentation = instrumentation;
      }
      p = await sourceTarget.buildOutlines();
      if (fullCompile) {
        p = await sourceTarget.buildProgram(trimDependencies: true);
        instrumentation?.finish();
        if (instrumentation != null && instrumentation.hasProblems) {
          if (updateComments) {
            await instrumentation.fixSource(description.uri, false);
          } else {
            return fail(null, instrumentation.problemsAsString);
          }
        }
      }
    } on InputError catch (e, s) {
      return fail(null, e.error, s);
    }
    return pass(p);
  }
}
