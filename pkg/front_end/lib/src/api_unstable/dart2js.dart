// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart'
    show messageMissingMain;

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessageHandler;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show StringToken;

import 'package:kernel/kernel.dart' show Component, Statement;

import 'package:kernel/ast.dart' as ir;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart' show CompilerOptions;

import '../api_prototype/experimental_flags.dart' show ExperimentalFlag;

import '../api_prototype/file_system.dart' show FileSystem;

import '../api_prototype/kernel_generator.dart' show CompilerResult;

import '../base/processed_options.dart' show ProcessedOptions;

import '../base/libraries_specification.dart' show LibrariesSpecification;

import '../base/nnbd_mode.dart' show NnbdMode;

import '../fasta/compiler_context.dart' show CompilerContext;

import '../kernel_generator_impl.dart' show generateKernelInternal;

import '../fasta/kernel/redirecting_factory_body.dart' as redirecting;

import 'compiler_state.dart' show InitializedCompilerState;

import 'util.dart' show equalLists, equalMaps;

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
    show CompilerOptions, parseExperimentalFlags, parseExperimentalArguments;

export '../api_prototype/experimental_flags.dart'
    show defaultExperimentalFlags, ExperimentalFlag, isExperimentEnabled;

export '../api_prototype/file_system.dart'
    show FileSystem, FileSystemEntity, FileSystemException;

export '../api_prototype/kernel_generator.dart' show kernelForProgram;

export '../api_prototype/language_version.dart'
    show uriUsesLegacyLanguageVersion;

export '../api_prototype/standard_file_system.dart' show DataFileSystemEntity;

export '../base/nnbd_mode.dart' show NnbdMode;

export '../compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

export '../fasta/kernel/redirecting_factory_body.dart'
    show isRedirectingFactoryField;

export '../fasta/operator.dart' show operatorFromString;

export 'compiler_state.dart' show InitializedCompilerState;

void clearStringTokenCanonicalizer() {
  // TODO(ahe): We should be able to remove this. Fasta should take care of
  // clearing the cache when.
  StringToken.canonicalizer.clear();
}

InitializedCompilerState initializeCompiler(
    InitializedCompilerState oldState,
    Target target,
    Uri librariesSpecificationUri,
    List<Uri> additionalDills,
    Uri packagesFileUri,
    {Map<ExperimentalFlag, bool> explicitExperimentalFlags,
    bool verify: false,
    NnbdMode nnbdMode}) {
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
      oldState.options.verify == verify &&
      oldState.options.nnbdMode == nnbdMode) {
    return oldState;
  }

  CompilerOptions options = new CompilerOptions()
    ..target = target
    ..additionalDills = additionalDills
    ..librariesSpecificationUri = librariesSpecificationUri
    ..packagesFileUri = packagesFileUri
    ..explicitExperimentalFlags = explicitExperimentalFlags
    ..verify = verify;
  if (nnbdMode != null) options.nnbdMode = nnbdMode;

  ProcessedOptions processedOpts = new ProcessedOptions(options: options);

  return new InitializedCompilerState(options, processedOpts);
}

Future<Component> compile(
    InitializedCompilerState state,
    bool verbose,
    FileSystem fileSystem,
    DiagnosticMessageHandler onDiagnostic,
    Uri input) async {
  CompilerOptions options = state.options;
  options
    ..onDiagnostic = onDiagnostic
    ..verbose = verbose
    ..fileSystem = fileSystem;

  ProcessedOptions processedOpts = state.processedOpts;
  processedOpts.inputs.clear();
  processedOpts.inputs.add(input);
  processedOpts.clearFileSystemCache();

  CompilerResult compilerResult = await CompilerContext.runWithOptions(
      processedOpts, (CompilerContext context) async {
    CompilerResult compilerResult = await generateKernelInternal();
    Component component = compilerResult?.component;
    if (component == null) return null;
    if (component.mainMethod == null) {
      context.options.report(
          messageMissingMain.withLocation(input, -1, 0), Severity.error);
      return null;
    }
    return compilerResult;
  });

  // Remove these parameters from [options] - they are no longer needed and
  // retain state from the previous compile. (http://dartbug.com/33708)
  options.onDiagnostic = null;
  options.fileSystem = null;
  return compilerResult?.component;
}

/// Retrieve the name of the libraries that are supported by [target] according
/// to the libraries specification [json] file.
///
/// Dart2js uses these names to determine the value of library environment
/// constants, such as `const bool.fromEnvironment("dart.library.io")`.
// TODO(sigmund): refactor dart2js so that we can retrieve this data later in
// the compilation pipeline. At that point we can get it from the CFE
// results directly and completely hide the libraries specification file from
// dart2js.
// TODO(sigmund): delete after all constant evaluation is done in the CFE, as
// this data will no longer be needed on the dart2js side.
Iterable<String> getSupportedLibraryNames(
    Uri librariesSpecificationUri, String json, String target) {
  return LibrariesSpecification.parse(librariesSpecificationUri, json)
      .specificationFor(target)
      .allLibraries
      .where((l) => l.isSupported)
      .map((l) => l.name);
}

/// Desugar API to determine whether [member] is a redirecting factory
/// constructor.
// TODO(sigmund): Delete this API once `member.isRedirectingFactoryConstructor`
// is implemented correctly for patch files (Issue #33495).
bool isRedirectingFactory(ir.Procedure member) {
  if (member.kind == ir.ProcedureKind.Factory) {
    Statement body = member.function.body;
    if (body is redirecting.RedirectingFactoryBody) return true;
    if (body is ir.ExpressionStatement) {
      ir.Expression expression = body.expression;
      if (expression is ir.Let) {
        if (expression.variable.name == redirecting.letName) {
          return true;
        }
      }
    }
  }
  return false;
}
