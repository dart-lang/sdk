// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.testing.suite;

import 'dart:async' show Future;

import 'dart:io' show File, Platform;

import 'dart:convert' show jsonDecode;

import 'package:front_end/src/api_prototype/standard_file_system.dart'
    show StandardFileSystem;

import 'package:front_end/src/base/libraries_specification.dart'
    show TargetLibrariesSpecification;

import 'package:front_end/src/fasta/testing/validating_instrumentation.dart'
    show ValidatingInstrumentation;

import 'package:front_end/src/fasta/uri_translator_impl.dart';

import 'package:kernel/ast.dart' show Library, Component;

import 'package:testing/testing.dart'
    show
        Chain,
        ChainContext,
        Expectation,
        ExpectationSet,
        Result,
        Step,
        TestDescription,
        StdioProcess;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/deprecated_problems.dart'
    show deprecated_InputError;

import 'package:front_end/src/fasta/testing/kernel_chain.dart'
    show MatchExpectation, Print, TypeCheck, Verify, WriteDill;

import 'package:front_end/src/fasta/ticker.dart' show Ticker;

import 'package:front_end/src/fasta/uri_translator.dart' show UriTranslator;

import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;

import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;

import 'package:kernel/kernel.dart' show loadComponentFromBytes;

import 'package:kernel/target/targets.dart' show TargetFlags;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:vm/target/vm.dart' show VmTarget;

export 'package:testing/testing.dart' show Chain, runMe;

const String STRONG_MODE = " strong mode ";

const String ENABLE_FULL_COMPILE = " full compile ";

const String EXPECTATIONS = '''
[
  {
    "name": "VerificationError",
    "group": "Fail"
  },
  {
    "name": "TypeCheckError",
    "group": "Fail"
  }
]
''';

String generateExpectationName(bool strongMode) {
  return strongMode ? "strong" : "direct";
}

class FastaContext extends ChainContext {
  final UriTranslatorImpl uriTranslator;
  final List<Step> steps;
  final Uri vm;
  final bool strongMode;
  final bool onlyCrashes;
  final Map<Component, KernelTarget> componentToTarget =
      <Component, KernelTarget>{};
  final Uri platformBinaries;
  Uri platformUri;
  Component platform;

  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(jsonDecode(EXPECTATIONS));
  Expectation verificationError;

  FastaContext(
      this.vm,
      this.strongMode,
      this.platformBinaries,
      this.onlyCrashes,
      bool ignoreExpectations,
      bool updateExpectations,
      bool updateComments,
      bool skipVm,
      this.uriTranslator,
      bool fullCompile)
      : steps = <Step>[
          new Outline(fullCompile, strongMode, updateComments: updateComments),
          const Print(),
          new Verify(fullCompile)
        ] {
    verificationError = expectationSet["VerificationError"];
    if (!ignoreExpectations) {
      steps.add(new MatchExpectation(
          fullCompile
              ? ".${generateExpectationName(strongMode)}.expect"
              : ".outline.expect",
          updateExpectations: updateExpectations));
    }
    if (strongMode) {
      steps.add(const TypeCheck());
    }
    if (fullCompile && !skipVm) {
      steps.add(const Transform());
      if (!ignoreExpectations) {
        steps.add(new MatchExpectation(
            fullCompile
                ? ".${generateExpectationName(strongMode)}.transformed.expect"
                : ".outline.transformed.expect",
            updateExpectations: updateExpectations));
      }
      steps.add(const WriteDill());
      steps.add(const Run());
    }
  }

  Future ensurePlatformUris() async {
    if (platformUri == null) {
      platformUri = platformBinaries
          .resolve(strongMode ? "vm_platform_strong.dill" : "vm_platform.dill");
    }
  }

  Future<Component> loadPlatform() async {
    if (platform == null) {
      await ensurePlatformUris();
      platform = loadComponentFromBytes(
          new File.fromUri(platformUri).readAsBytesSync());
    }
    return platform;
  }

  @override
  Result processTestResult(
      TestDescription description, Result result, bool last) {
    if (onlyCrashes) {
      Expectation outcome = result.outcome;
      if (outcome == Expectation.Crash || outcome == verificationError) {
        return result;
      }
      return result.copyWithOutcome(Expectation.Pass);
    }
    return super.processTestResult(description, result, last);
  }

  static Future<FastaContext> create(
      Chain suite, Map<String, String> environment) async {
    Uri sdk = Uri.base.resolve("sdk/");
    Uri vm = Uri.base.resolveUri(new Uri.file(Platform.resolvedExecutable));
    Uri packages = Uri.base.resolve(".packages");
    var options = new ProcessedOptions(new CompilerOptions()
      ..sdkRoot = sdk
      ..packagesFileUri = packages);
    UriTranslator uriTranslator = await options.getUriTranslator();
    bool strongMode = environment.containsKey(STRONG_MODE);
    bool onlyCrashes = environment["onlyCrashes"] == "true";
    bool ignoreExpectations = environment["ignoreExpectations"] == "true";
    bool updateExpectations = environment["updateExpectations"] == "true";
    bool updateComments = environment["updateComments"] == "true";
    bool skipVm = environment["skipVm"] == "true";
    String platformBinaries = environment["platformBinaries"];
    if (platformBinaries != null && !platformBinaries.endsWith('/')) {
      platformBinaries = '$platformBinaries/';
    }
    return new FastaContext(
        vm,
        strongMode,
        platformBinaries == null
            ? computePlatformBinariesLocation()
            : Uri.base.resolve(platformBinaries),
        onlyCrashes,
        ignoreExpectations,
        updateExpectations,
        updateComments,
        skipVm,
        uriTranslator,
        environment.containsKey(ENABLE_FULL_COMPILE));
  }
}

class Run extends Step<Uri, int, FastaContext> {
  const Run();

  String get name => "run";

  bool get isAsync => true;

  bool get isRuntime => true;

  Future<Result<int>> run(Uri uri, FastaContext context) async {
    if (context.platformUri == null) {
      throw "Executed `Run` step before initializing the context.";
    }
    File generated = new File.fromUri(uri);
    StdioProcess process;
    try {
      var args = <String>[];
      if (context.strongMode) {
        args.add('--strong');
        args.add('--reify-generic-functions');
      }
      args.add(generated.path);
      process = await StdioProcess.run(context.vm.toFilePath(), args);
      print(process.output);
    } finally {
      generated.parent.delete(recursive: true);
    }
    return process.toResult();
  }
}

class Outline extends Step<TestDescription, Component, FastaContext> {
  final bool fullCompile;

  final bool strongMode;

  const Outline(this.fullCompile, this.strongMode,
      {this.updateComments: false});

  final bool updateComments;

  String get name {
    return fullCompile ? "compile" : "outline";
  }

  bool get isCompiler => fullCompile;

  Future<Result<Component>> run(
      TestDescription description, FastaContext context) async {
    var options = new ProcessedOptions(new CompilerOptions());
    return await CompilerContext.runWithOptions(options, (_) async {
      // Disable colors to ensure that expectation files are the same across
      // platforms and independent of stdin/stderr.
      CompilerContext.current.disableColors();
      Component platform = await context.loadPlatform();
      Ticker ticker = new Ticker();
      DillTarget dillTarget = new DillTarget(ticker, context.uriTranslator,
          new TestVmTarget(new TargetFlags(strongMode: strongMode)));
      dillTarget.loader.appendLibraries(platform);
      // We create a new URI translator to avoid reading platform libraries from
      // file system.
      UriTranslatorImpl uriTranslator = new UriTranslatorImpl(
          const TargetLibrariesSpecification('vm'),
          context.uriTranslator.packages);
      KernelTarget sourceTarget = new KernelTarget(
          StandardFileSystem.instance, false, dillTarget, uriTranslator);

      Component p;
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
          p = await sourceTarget.buildComponent();
          instrumentation?.finish();
          if (instrumentation != null && instrumentation.hasProblems) {
            if (updateComments) {
              await instrumentation.fixSource(description.uri, false);
            } else {
              return fail(null, instrumentation.problemsAsString);
            }
          }
        }
      } on deprecated_InputError catch (e, s) {
        return fail(null, e.message.message, s);
      }
      context.componentToTarget.clear();
      context.componentToTarget[p] = sourceTarget;
      return pass(p);
    });
  }
}

class Transform extends Step<Component, Component, FastaContext> {
  const Transform();

  String get name => "transform component";

  Future<Result<Component>> run(
      Component component, FastaContext context) async {
    KernelTarget sourceTarget = context.componentToTarget[component];
    context.componentToTarget.remove(component);
    TestVmTarget backendTarget = sourceTarget.backendTarget;
    backendTarget.enabled = true;
    try {
      if (sourceTarget.loader.coreTypes != null) {
        sourceTarget.runBuildTransformations();
      }
    } finally {
      backendTarget.enabled = false;
    }
    return pass(component);
  }
}

class TestVmTarget extends VmTarget {
  bool enabled = false;

  TestVmTarget(TargetFlags flags) : super(flags);

  String get name => "vm";

  @override
  void performModularTransformationsOnLibraries(Component component,
      CoreTypes coreTypes, ClassHierarchy hierarchy, List<Library> libraries,
      {void logger(String msg)}) {
    if (enabled) {
      super.performModularTransformationsOnLibraries(
          component, coreTypes, hierarchy, libraries,
          logger: logger);
    }
  }
}
