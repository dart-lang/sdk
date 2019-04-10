// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;

import 'package:kernel/kernel.dart' show Component;

import 'package:kernel/target/targets.dart' show Target;

import '../api_prototype/compiler_options.dart' show CompilerOptions;

import '../api_prototype/diagnostic_message.dart' show DiagnosticMessageHandler;

import '../api_prototype/experimental_flags.dart' show ExperimentalFlag;

import '../api_prototype/file_system.dart' show FileSystem;

import '../base/processed_options.dart' show ProcessedOptions;

import '../base/libraries_specification.dart' show LibrariesSpecification;

import '../fasta/compiler_context.dart' show CompilerContext;

import '../fasta/fasta_codes.dart' show messageMissingMain;

import '../fasta/severity.dart' show Severity;

import '../kernel_generator_impl.dart' show generateKernelInternal;

import '../fasta/scanner.dart' show ErrorToken, StringToken, Token;

import 'compiler_state.dart' show InitializedCompilerState;

export '../api_prototype/compiler_options.dart'
    show CompilerOptions, parseExperimentalFlags;

export '../api_prototype/diagnostic_message.dart'
    show
        DiagnosticMessage,
        getMessageCharOffset,
        getMessageHeaderText,
        getMessageLength,
        getMessageRelatedInformation,
        getMessageUri;

export '../api_prototype/experimental_flags.dart'
    show defaultExperimentalFlags, ExperimentalFlag;

export '../api_prototype/file_system.dart'
    show FileSystem, FileSystemEntity, FileSystemException;

export '../api_prototype/kernel_generator.dart' show kernelForProgram;

export '../api_prototype/standard_file_system.dart' show DataFileSystemEntity;

export '../compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

export '../fasta/fasta_codes.dart' show LocatedMessage;

export '../fasta/kernel/redirecting_factory_body.dart'
    show RedirectingFactoryBody;

export '../fasta/operator.dart' show operatorFromString;

export '../fasta/parser/async_modifier.dart' show AsyncModifier;

export '../fasta/scanner.dart' show isUserDefinableOperator, isMinusOperator;

export '../fasta/scanner/characters.dart'
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

export '../fasta/severity.dart' show Severity;

export '../fasta/util/link.dart' show Link, LinkBuilder;

export '../fasta/util/link_implementation.dart' show LinkEntry;

export '../fasta/util/relativize.dart' show relativizeUri;

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
    List<Uri> linkedDependencies,
    Uri packagesFileUri,
    {List<Uri> dependencies,
    Map<ExperimentalFlag, bool> experimentalFlags,
    bool verify: false,
    bool enableAsserts: false}) {
  bool mapEqual(Map<ExperimentalFlag, bool> a, Map<ExperimentalFlag, bool> b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var flag in a.keys) {
      if (!b.containsKey(flag) || a[flag] != b[flag]) return false;
    }
    return true;
  }

  bool listEqual(List<Uri> a, List<Uri> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; ++i) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  linkedDependencies.sort((a, b) => a.toString().compareTo(b.toString()));

  if (oldState != null &&
      oldState.options.packagesFileUri == packagesFileUri &&
      oldState.options.librariesSpecificationUri == librariesSpecificationUri &&
      listEqual(oldState.options.linkedDependencies, linkedDependencies) &&
      mapEqual(oldState.options.experimentalFlags, experimentalFlags)) {
    return oldState;
  }

  CompilerOptions options = new CompilerOptions()
    ..target = target
    ..legacyMode = target.legacyMode
    ..linkedDependencies = linkedDependencies
    ..librariesSpecificationUri = librariesSpecificationUri
    ..packagesFileUri = packagesFileUri
    ..experimentalFlags = experimentalFlags
    ..verify = verify
    ..enableAsserts = enableAsserts;

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

  var compilerResult = await CompilerContext.runWithOptions(processedOpts,
      (CompilerContext context) async {
    var compilerResult = await generateKernelInternal();
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

Object tokenToString(Object value) {
  // TODO(ahe): This method is most likely unnecessary. Dart2js doesn't see
  // tokens anymore.
  if (value is ErrorToken) {
    // Shouldn't happen.
    return value.assertionMessage.message;
  } else if (value is Token) {
    return value.lexeme;
  } else {
    return value;
  }
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
