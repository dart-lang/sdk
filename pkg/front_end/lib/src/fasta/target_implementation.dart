// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.target_implementation;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:kernel/ast.dart' show Library, Source, Version;

import 'package:kernel/target/targets.dart' as backend show Target;

import '../base/processed_options.dart' show ProcessedOptions;

import 'builder/class_builder.dart';
import 'builder/library_builder.dart';
import 'builder/member_builder.dart';

import 'compiler_context.dart' show CompilerContext;

import 'loader.dart' show Loader;

import 'messages.dart' show FormattedMessage, LocatedMessage, Message;

import 'rewrite_severity.dart' show rewriteSeverity;

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

  MemberBuilder cachedAbstractClassInstantiationError;
  MemberBuilder cachedCompileTimeError;
  MemberBuilder cachedDuplicatedFieldInitializerError;
  MemberBuilder cachedNativeAnnotation;

  final ProcessedOptions _options;

  TargetImplementation(Ticker ticker, this.uriTranslator, this.backendTarget)
      : assert(ticker != null),
        assert(uriTranslator != null),
        assert(backendTarget != null),
        _options = CompilerContext.current.options,
        super(ticker);

  bool isExperimentEnabledInLibrary(ExperimentalFlag flag, Uri importUri) {
    return _options.isExperimentEnabledInLibrary(flag, importUri);
  }

  Version getExperimentEnabledVersionInLibrary(
      ExperimentalFlag flag, Uri importUri) {
    return _options.getExperimentEnabledVersionInLibrary(flag, importUri);
  }

  /// Returns `true` if the [flag] is enabled by default.
  bool isExperimentEnabledByDefault(ExperimentalFlag flag) {
    return _options.isExperimentEnabledByDefault(flag);
  }

  /// Returns `true` if the [flag] is enabled globally.
  ///
  /// This is `true` either if the [flag] is passed through an explicit
  /// `--enable-experiment` option or if the [flag] is expired and on by
  /// default.
  bool isExperimentEnabledGlobally(ExperimentalFlag flag) {
    return _options.isExperimentEnabledGlobally(flag);
  }

  /// Creates a [LibraryBuilder] corresponding to [uri], if one doesn't exist
  /// already.
  ///
  /// [fileUri] must not be null and is a URI that can be passed to FileSystem
  /// to locate the corresponding file.
  ///
  /// [origin] is non-null if the created library is a patch to [origin].
  ///
  /// [packageUri] is the base uri for the package which the library belongs to.
  /// For instance 'package:foo'.
  ///
  /// This is used to associate libraries in for instance the 'bin' and 'test'
  /// folders of a package source with the package uri of the 'lib' folder.
  ///
  /// If the [packageUri] is `null` the package association of this library is
  /// based on its [importUri].
  ///
  /// For libraries with a 'package:' [importUri], the package path must match
  /// the path in the [importUri]. For libraries with a 'dart:' [importUri] the
  /// [packageUri] must be `null`.
  LibraryBuilder createLibraryBuilder(
      Uri uri,
      Uri fileUri,
      Uri packageUri,
      covariant LibraryBuilder origin,
      Library referencesFrom,
      bool referenceIsPartOwner);

  /// The class [cls] is involved in a cyclic definition. This method should
  /// ensure that the cycle is broken, for example, by removing superclass and
  /// implemented interfaces.
  void breakCycle(ClassBuilder cls);

  Uri translateUri(Uri uri) => uriTranslator.translate(uri);

  /// Returns a reference to the constructor of
  /// [AbstractClassInstantiationError] error.  The constructor is expected to
  /// accept a single argument of type String, which is the name of the
  /// abstract class.
  MemberBuilder getAbstractClassInstantiationError(Loader loader) {
    if (cachedAbstractClassInstantiationError != null) {
      return cachedAbstractClassInstantiationError;
    }
    return cachedAbstractClassInstantiationError =
        loader.coreLibrary.getConstructor("AbstractClassInstantiationError");
  }

  /// Returns a reference to the constructor used for creating a compile-time
  /// error. The constructor is expected to accept a single argument of type
  /// String, which is the compile-time error message.
  MemberBuilder getCompileTimeError(Loader loader) {
    if (cachedCompileTimeError != null) return cachedCompileTimeError;
    return cachedCompileTimeError = loader.coreLibrary
        .getConstructor("_CompileTimeError", bypassLibraryPrivacy: true);
  }

  /// Returns a reference to the constructor used for creating a runtime error
  /// when a final field is initialized twice. The constructor is expected to
  /// accept a single argument which is the name of the field.
  MemberBuilder getDuplicatedFieldInitializerError(Loader loader) {
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
  MemberBuilder getNativeAnnotation(Loader loader) {
    if (cachedNativeAnnotation != null) return cachedNativeAnnotation;
    LibraryBuilder internal = loader.read(Uri.parse("dart:_internal"), -1,
        accessor: loader.coreLibrary);
    return cachedNativeAnnotation = internal.getConstructor("ExternalName");
  }

  void loadExtraRequiredLibraries(Loader loader) {
    for (String uri in backendTarget.extraRequiredLibraries) {
      loader.read(Uri.parse(uri), 0, accessor: loader.coreLibrary);
    }
    if (context.compilingPlatform) {
      for (String uri in backendTarget.extraRequiredLibrariesPlatform) {
        loader.read(Uri.parse(uri), 0, accessor: loader.coreLibrary);
      }
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
      Severity severity,
      {List<Uri> involvedFiles}) {
    ProcessedOptions processedOptions = context.options;
    return processedOptions.format(
        message.withLocation(fileUri, charOffset, length),
        severity,
        messageContext,
        involvedFiles: involvedFiles);
  }

  Severity fixSeverity(Severity severity, Message message, Uri fileUri) {
    severity ??= message.code.severity;
    return rewriteSeverity(severity, message.code, fileUri);
  }

  String get currentSdkVersionString {
    return CompilerContext.current.options.currentSdkVersion;
  }

  Version _currentSdkVersion;
  Version get currentSdkVersion {
    if (_currentSdkVersion != null) return _currentSdkVersion;
    _parseCurrentSdkVersion();
    return _currentSdkVersion;
  }

  void _parseCurrentSdkVersion() {
    bool good = false;
    if (currentSdkVersionString != null) {
      List<String> dotSeparatedParts = currentSdkVersionString.split(".");
      if (dotSeparatedParts.length >= 2) {
        _currentSdkVersion = new Version(int.tryParse(dotSeparatedParts[0]),
            int.tryParse(dotSeparatedParts[1]));
        good = true;
      }
    }
    if (!good) {
      throw new StateError(
          "Unparsable sdk version given: $currentSdkVersionString");
    }
  }

  void releaseAncillaryResources();
}
