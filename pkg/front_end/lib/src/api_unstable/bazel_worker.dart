// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// API needed by `utils/front_end/summary_worker.dart`, a tool used to compute
/// summaries in build systems like bazel, pub-build, and package-build.

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessageHandler;

import 'package:front_end/src/api_prototype/compiler_options.dart';

import 'package:kernel/kernel.dart' show Component, Library;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart'
    show CompilerOptions, parseExperimentalFlags;

import '../api_prototype/experimental_flags.dart' show ExperimentalFlag;

import '../api_prototype/file_system.dart' show FileSystem;

import '../api_prototype/front_end.dart' show CompilerResult;

import '../base/nnbd_mode.dart' show NnbdMode;

import '../base/processed_options.dart' show ProcessedOptions;

import '../kernel_generator_impl.dart' show generateKernel;

import 'compiler_state.dart' show InitializedCompilerState;

import 'modular_incremental_compilation.dart' as modular
    show initializeIncrementalCompiler;

export 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessage;

export 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

export '../api_prototype/compiler_options.dart'
    show parseExperimentalFlags, parseExperimentalArguments;

export '../api_prototype/experimental_flags.dart'
    show ExperimentalFlag, parseExperimentalFlag;

export '../api_prototype/standard_file_system.dart' show StandardFileSystem;

export '../api_prototype/terminal_color_support.dart'
    show printDiagnosticMessage;

export '../base/nnbd_mode.dart' show NnbdMode;

export '../fasta/kernel/utils.dart' show serializeComponent;

export 'compiler_state.dart' show InitializedCompilerState;

/// Initializes the compiler for a modular build.
///
/// Re-uses cached components from [oldState.workerInputCache], and reloads them
/// as necessary based on [workerInputDigests].
Future<InitializedCompilerState> initializeIncrementalCompiler(
    InitializedCompilerState oldState,
    Set<String> tags,
    Uri sdkSummary,
    Uri packagesFile,
    Uri librariesSpecificationUri,
    List<Uri> additionalDills,
    Map<Uri, List<int>> workerInputDigests,
    Target target,
    FileSystem fileSystem,
    Iterable<String> experiments,
    bool outlineOnly,
    Map<String, String> environmentDefines,
    {bool trackNeededDillLibraries: false,
    bool verbose: false,
    NnbdMode nnbdMode: NnbdMode.Weak}) async {
  List<Component> outputLoadedAdditionalDills =
      new List<Component>.filled(additionalDills.length, null);
  Map<ExperimentalFlag, bool> experimentalFlags = parseExperimentalFlags(
      parseExperimentalArguments(experiments),
      onError: (e) => throw e);
  return modular.initializeIncrementalCompiler(
      oldState,
      tags,
      outputLoadedAdditionalDills,
      sdkSummary,
      packagesFile,
      librariesSpecificationUri,
      additionalDills,
      workerInputDigests,
      target,
      fileSystem: fileSystem,
      explicitExperimentalFlags: experimentalFlags,
      outlineOnly: outlineOnly,
      omitPlatform: true,
      trackNeededDillLibraries: trackNeededDillLibraries,
      environmentDefines: environmentDefines,
      verbose: verbose,
      nnbdMode: nnbdMode);
}

Future<InitializedCompilerState> initializeCompiler(
  InitializedCompilerState oldState,
  Uri sdkSummary,
  Uri librariesSpecificationUri,
  Uri packagesFile,
  List<Uri> additionalDills,
  Target target,
  FileSystem fileSystem,
  Iterable<String> experiments,
  Map<String, String> environmentDefines, {
  bool verbose: false,
  NnbdMode nnbdMode: NnbdMode.Weak,
}) async {
  // TODO(sigmund): use incremental compiler when it supports our use case.
  // Note: it is common for the summary worker to invoke the compiler with the
  // same input summary URIs, but with different contents, so we'd need to be
  // able to track shas or modification time-stamps to be able to invalidate the
  // old state appropriately.
  CompilerOptions options = new CompilerOptions()
    ..sdkSummary = sdkSummary
    ..packagesFileUri = packagesFile
    ..librariesSpecificationUri = librariesSpecificationUri
    ..additionalDills = additionalDills
    ..target = target
    ..fileSystem = fileSystem
    ..environmentDefines = environmentDefines
    ..explicitExperimentalFlags = parseExperimentalFlags(
        parseExperimentalArguments(experiments),
        onError: (e) => throw e)
    ..verbose = verbose
    ..nnbdMode = nnbdMode;

  ProcessedOptions processedOpts = new ProcessedOptions(options: options);

  return new InitializedCompilerState(options, processedOpts);
}

Future<CompilerResult> _compile(InitializedCompilerState compilerState,
    List<Uri> inputs, DiagnosticMessageHandler diagnosticMessageHandler,
    {bool summaryOnly, bool includeOffsets: true}) {
  summaryOnly ??= true;
  CompilerOptions options = compilerState.options;
  options..onDiagnostic = diagnosticMessageHandler;

  ProcessedOptions processedOpts = compilerState.processedOpts;
  processedOpts.inputs.clear();
  processedOpts.inputs.addAll(inputs);

  return generateKernel(processedOpts,
      buildSummary: summaryOnly,
      buildComponent: !summaryOnly,
      includeOffsets: includeOffsets);
}

Future<List<int>> compileSummary(InitializedCompilerState compilerState,
    List<Uri> inputs, DiagnosticMessageHandler diagnosticMessageHandler,
    {bool includeOffsets: false}) async {
  CompilerResult result = await _compile(
      compilerState, inputs, diagnosticMessageHandler,
      summaryOnly: true, includeOffsets: includeOffsets);
  return result?.summary;
}

Future<Component> compileComponent(InitializedCompilerState compilerState,
    List<Uri> inputs, DiagnosticMessageHandler diagnosticMessageHandler) async {
  CompilerResult result = await _compile(
      compilerState, inputs, diagnosticMessageHandler,
      summaryOnly: false);

  Component component = result?.component;
  if (component != null) {
    for (Library lib in component.libraries) {
      if (!inputs.contains(lib.importUri)) {
        // Excluding the library also means that their canonical names will not
        // be computed as part of serialization, so we need to do that
        // preemptively here to avoid errors when serializing references to
        // elements of these libraries.
        component.root.getChildFromUri(lib.importUri).bindTo(lib.reference);
        lib.computeCanonicalNames();
      }
    }
  }
  return component;
}
