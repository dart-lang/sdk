// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.target_implementation;

import 'package:kernel/ast.dart' show Source;

import 'package:kernel/target/targets.dart' as backend show Target;

import '../base/processed_options.dart' show ProcessedOptions;

import 'builder/builder.dart' show Declaration, ClassBuilder, LibraryBuilder;

import 'compiler_context.dart' show CompilerContext;

import 'loader.dart' show Loader;

import 'messages.dart' show FormattedMessage, LocatedMessage, Message;

import 'rewrite_severity.dart' show rewriteSeverity;

import 'severity.dart' show Severity;

import 'target.dart' show Target;

import 'ticker.dart' show Ticker;

import 'uri_translator.dart' show UriTranslator;

import '../api_prototype/experimental_flags.dart' show ExperimentalFlag;

/// Provides the implementation details used by a loader for a target.
abstract class TargetImplementation extends Target {
  final UriTranslator uriTranslator;

  final backend.Target backendTarget;

  final CompilerContext context = CompilerContext.current;

  /// Shared with [CompilerContext].
  final Map<Uri, Source> uriToSource = CompilerContext.current.uriToSource;

  Declaration cachedAbstractClassInstantiationError;
  Declaration cachedCompileTimeError;
  Declaration cachedDuplicatedFieldInitializerError;
  Declaration cachedFallThroughError;
  Declaration cachedNativeAnnotation;
  Declaration cachedNativeExtensionAnnotation;

  bool enableConstantUpdate2018;
  bool enableControlFlowCollections;
  bool enableSetLiterals;
  bool enableSpreadCollections;

  TargetImplementation(Ticker ticker, this.uriTranslator, this.backendTarget)
      : enableConstantUpdate2018 = CompilerContext.current.options
            .isExperimentEnabled(ExperimentalFlag.constantUpdate2018),
        enableControlFlowCollections = CompilerContext.current.options
            .isExperimentEnabled(ExperimentalFlag.controlFlowCollections),
        enableSetLiterals = CompilerContext.current.options
            .isExperimentEnabled(ExperimentalFlag.setLiterals),
        enableSpreadCollections = CompilerContext.current.options
            .isExperimentEnabled(ExperimentalFlag.spreadCollections),
        super(ticker);

  /// Creates a [LibraryBuilder] corresponding to [uri], if one doesn't exist
  /// already.
  ///
  /// [fileUri] must not be null and is a URI that can be passed to FileSystem
  /// to locate the corresponding file.
  ///
  /// [origin] is non-null if the created library is a patch to [origin].
  LibraryBuilder createLibraryBuilder(
      Uri uri, Uri fileUri, covariant LibraryBuilder origin);

  /// The class [cls] is involved in a cyclic definition. This method should
  /// ensure that the cycle is broken, for example, by removing superclass and
  /// implemented interfaces.
  void breakCycle(ClassBuilder cls);

  Uri translateUri(Uri uri) => uriTranslator.translate(uri);

  /// Returns a reference to the constructor of
  /// [AbstractClassInstantiationError] error.  The constructor is expected to
  /// accept a single argument of type String, which is the name of the
  /// abstract class.
  Declaration getAbstractClassInstantiationError(Loader loader) {
    if (cachedAbstractClassInstantiationError != null) {
      return cachedAbstractClassInstantiationError;
    }
    return cachedAbstractClassInstantiationError =
        loader.coreLibrary.getConstructor("AbstractClassInstantiationError");
  }

  /// Returns a reference to the constructor used for creating a compile-time
  /// error. The constructor is expected to accept a single argument of type
  /// String, which is the compile-time error message.
  Declaration getCompileTimeError(Loader loader) {
    if (cachedCompileTimeError != null) return cachedCompileTimeError;
    return cachedCompileTimeError = loader.coreLibrary
        .getConstructor("_CompileTimeError", bypassLibraryPrivacy: true);
  }

  /// Returns a reference to the constructor used for creating a runtime error
  /// when a final field is initialized twice. The constructor is expected to
  /// accept a single argument which is the name of the field.
  Declaration getDuplicatedFieldInitializerError(Loader loader) {
    if (cachedDuplicatedFieldInitializerError != null) {
      return cachedDuplicatedFieldInitializerError;
    }
    return cachedDuplicatedFieldInitializerError = loader.coreLibrary
        .getConstructor("_DuplicatedFieldInitializerError",
            bypassLibraryPrivacy: true);
  }

  /// Returns a reference to the constructor used for creating `native`
  /// annotations. The constructor is expected to accept a single argument of
  /// type String, which is the name of the native method.
  Declaration getNativeAnnotation(Loader loader) {
    if (cachedNativeAnnotation != null) return cachedNativeAnnotation;
    LibraryBuilder internal = loader.read(Uri.parse("dart:_internal"), -1,
        accessor: loader.coreLibrary);
    return cachedNativeAnnotation = internal.getConstructor("ExternalName");
  }

  void loadExtraRequiredLibraries(Loader loader) {
    for (String uri in backendTarget.extraRequiredLibraries) {
      loader.read(Uri.parse(uri), 0, accessor: loader.coreLibrary);
    }
  }

  void addSourceInformation(
      Uri importUri, Uri fileUri, List<int> lineStarts, List<int> sourceCode);

  void readPatchFiles(covariant LibraryBuilder library) {}

  FormattedMessage createFormattedMessage(
      Message message,
      int charOffset,
      int length,
      Uri fileUri,
      List<LocatedMessage> messageContext,
      Severity severity) {
    ProcessedOptions processedOptions = context.options;
    return processedOptions.format(
        message.withLocation(fileUri, charOffset, length),
        severity,
        messageContext);
  }

  Severity fixSeverity(Severity severity, Message message, Uri fileUri) {
    severity ??= message.code.severity;
    if (severity == Severity.errorLegacyWarning) {
      severity = backendTarget.legacyMode ? Severity.warning : Severity.error;
    }
    return rewriteSeverity(severity, message.code, fileUri);
  }
}
