// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show messageMissingMain;

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessageHandler;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:kernel/kernel.dart' show Component;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart'
    show CompilerOptions, InvocationMode, Verbosity;

import '../api_prototype/experimental_flags.dart' show ExperimentalFlag;

import '../api_prototype/file_system.dart' show FileSystem, NullFileSystem;

import '../api_prototype/kernel_generator.dart' show CompilerResult;

import '../base/processed_options.dart' show ProcessedOptions;

import '../base/nnbd_mode.dart' show NnbdMode;

import '../fasta/compiler_context.dart' show CompilerContext;

import '../kernel_generator_impl.dart' show generateKernelInternal;

import 'compiler_state.dart' show InitializedCompilerState;

import 'util.dart' show equalLists, equalMaps, equalSets;

export 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show LocatedMessage;

export 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show
        DiagnosticMessage,
        DiagnosticMessageHandler,
        getMessageCharOffset,
        getMessageHeaderText,
        getMessageLength,
        getMessageRelatedInformation,
        getMessageUri;

export 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

export 'package:_fe_analyzer_shared/src/parser/async_modifier.dart'
    show AsyncModifier;

export 'package:_fe_analyzer_shared/src/scanner/scanner.dart'
    show isUserDefinableOperator, isMinusOperator;

export 'package:_fe_analyzer_shared/src/scanner/characters.dart'
    show
        $$,
        $0,
        $9,
        $A,
        $BACKSLASH,
        $CR,
        $DEL,
        $DQ,
        $HASH,
        $LF,
        $LS,
        $PS,
        $TAB,
        $Z,
        $_,
        $a,
        $g,
        $s,
        $z;

export 'package:_fe_analyzer_shared/src/util/filenames.dart'
    show nativeToUri, nativeToUriPath, uriPathToNative;

export 'package:_fe_analyzer_shared/src/util/link.dart' show Link, LinkBuilder;

export 'package:_fe_analyzer_shared/src/util/link_implementation.dart'
    show LinkEntry;

export 'package:_fe_analyzer_shared/src/util/relativize.dart'
    show relativizeUri;

export '../api_prototype/compiler_options.dart'
    show
        CompilerOptions,
        InvocationMode,
        Verbosity,
        parseExperimentalFlags,
        parseExperimentalArguments;

export '../api_prototype/const_conditional_simplifier.dart';

export '../api_prototype/constant_evaluator.dart';

export '../api_prototype/experimental_flags.dart'
    show defaultExperimentalFlags, ExperimentalFlag, isExperimentEnabled;

export '../api_prototype/file_system.dart'
    show FileSystem, FileSystemEntity, FileSystemException;

export '../api_prototype/kernel_generator.dart' show kernelForProgram;

export '../api_prototype/language_version.dart'
    show uriUsesLegacyLanguageVersion;

export '../api_prototype/standard_file_system.dart' show DataFileSystemEntity;

export '../api_prototype/try_constant_evaluator.dart';

export '../base/nnbd_mode.dart' show NnbdMode;

export '../compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

export '../fasta/operator.dart' show operatorFromString;

export 'compiler_state.dart' show InitializedCompilerState;

InitializedCompilerState initializeCompiler(
    InitializedCompilerState? oldState,
    Target target,
    Uri? librariesSpecificationUri,
    List<Uri> additionalDills,
    Uri? packagesFileUri,
    {required Map<ExperimentalFlag, bool> explicitExperimentalFlags,
    Map<String, String>? environmentDefines,
    bool verify = false,
    NnbdMode? nnbdMode,
    Set<InvocationMode> invocationModes = const <InvocationMode>{},
    Verbosity verbosity = Verbosity.all}) {
  additionalDills.sort((a, b) => a.toString().compareTo(b.toString()));

  // We don't check `target` because it doesn't support '==' and each
  // compilation passes a fresh target. However, we pass a logically identical
  // target each time, so it is safe to assume that it never changes.
  if (oldState != null &&
      oldState.options.packagesFileUri == packagesFileUri &&
      oldState.options.librariesSpecificationUri == librariesSpecificationUri &&
      equalLists(oldState.options.additionalDills, additionalDills) &&
      equalMaps(oldState.options.explicitExperimentalFlags,
          explicitExperimentalFlags) &&
      equalMaps(oldState.options.environmentDefines, environmentDefines) &&
      oldState.options.verify == verify &&
      oldState.options.nnbdMode == nnbdMode &&
      equalSets(oldState.options.invocationModes, invocationModes) &&
      oldState.options.verbosity == verbosity) {
    return oldState;
  }

  CompilerOptions options = new CompilerOptions()
    ..target = target
    ..additionalDills = additionalDills
    ..librariesSpecificationUri = librariesSpecificationUri
    ..packagesFileUri = packagesFileUri
    ..explicitExperimentalFlags = explicitExperimentalFlags
    ..environmentDefines = environmentDefines
    ..errorOnUnevaluatedConstant = environmentDefines != null ? true : false
    ..verify = verify
    ..invocationModes = invocationModes
    ..verbosity = verbosity;
  if (nnbdMode != null) options.nnbdMode = nnbdMode;

  ProcessedOptions processedOpts = new ProcessedOptions(options: options);

  return new InitializedCompilerState(options, processedOpts);
}

Future<Component?> compile(
    InitializedCompilerState state,
    bool verbose,
    FileSystem fileSystem,
    DiagnosticMessageHandler onDiagnostic,
    List<Uri> inputs,
    bool isModularCompile) async {
  assert(inputs.length == 1 || isModularCompile);
  CompilerOptions options = state.options;
  options
    ..onDiagnostic = onDiagnostic
    ..verbose = verbose
    ..fileSystem = fileSystem;

  ProcessedOptions processedOpts = state.processedOpts;
  processedOpts.inputs.clear();
  processedOpts.inputs.addAll(inputs);
  processedOpts.clearFileSystemCache();

  CompilerResult? compilerResult = await CompilerContext.runWithOptions(
      processedOpts, (CompilerContext context) async {
    CompilerResult compilerResult = await generateKernelInternal();
    Component? component = compilerResult.component;
    if (component == null) return null;
    if (component.mainMethod == null && !isModularCompile) {
      context.options.report(
          messageMissingMain.withLocation(inputs.single, -1, 0),
          Severity.error);
      return null;
    }
    return compilerResult;
  });

  // Remove these parameters from [options] - they are no longer needed and
  // retain state from the previous compile. (http://dartbug.com/33708)
  options.onDiagnostic = null;
  options.fileSystem = const NullFileSystem();
  return compilerResult?.component;
}
