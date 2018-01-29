// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.target_implementation;

import 'package:kernel/target/targets.dart' as backend show Target;

import 'builder/builder.dart' show Builder, ClassBuilder, LibraryBuilder;

import 'compiler_context.dart' show CompilerContext;

import 'loader.dart' show Loader;

import 'target.dart' show Target;

import 'ticker.dart' show Ticker;

import 'uri_translator.dart' show UriTranslator;

/// Provides the implementation details used by a loader for a target.
abstract class TargetImplementation extends Target {
  final UriTranslator uriTranslator;

  final backend.Target backendTarget;

  final CompilerContext context = CompilerContext.current;

  Builder cachedAbstractClassInstantiationError;
  Builder cachedCompileTimeError;
  Builder cachedDuplicatedFieldInitializerError;
  Builder cachedFallThroughError;
  Builder cachedNativeAnnotation;
  Builder cachedNativeExtensionAnnotation;

  TargetImplementation(Ticker ticker, this.uriTranslator, this.backendTarget)
      : super(ticker);

  /// Creates a [LibraryBuilder] corresponding to [uri], if one doesn't exist
  /// already.
  ///
  /// [fileUri] must not be null and is a URI that can be passed to FileSystem
  /// to locate the corresponding file.
  ///
  /// [origin] is non-null if the created library is a patch to [origin].
  LibraryBuilder createLibraryBuilder(
      Uri uri, Uri fileUri, covariant LibraryBuilder origin);

  /// Add the classes extended or implemented directly by [cls] to [set].
  void addDirectSupertype(ClassBuilder cls, Set<ClassBuilder> set);

  /// The class [cls] is involved in a cyclic definition. This method should
  /// ensure that the cycle is broken, for example, by removing superclass and
  /// implemented interfaces.
  void breakCycle(ClassBuilder cls);

  Uri translateUri(Uri uri) => uriTranslator.translate(uri);

  /// Returns a reference to the constructor of
  /// [AbstractClassInstantiationError] error.  The constructor is expected to
  /// accept a single argument of type String, which is the name of the
  /// abstract class.
  Builder getAbstractClassInstantiationError(Loader loader) {
    if (cachedAbstractClassInstantiationError != null) {
      return cachedAbstractClassInstantiationError;
    }
    return cachedAbstractClassInstantiationError =
        loader.coreLibrary.getConstructor("AbstractClassInstantiationError");
  }

  /// Returns a reference to the constructor used for creating a compile-time
  /// error. The constructor is expected to accept a single argument of type
  /// String, which is the compile-time error message.
  Builder getCompileTimeError(Loader loader) {
    if (cachedCompileTimeError != null) return cachedCompileTimeError;
    return cachedCompileTimeError = loader.coreLibrary
        .getConstructor("_CompileTimeError", bypassLibraryPrivacy: true);
  }

  /// Returns a reference to the constructor used for creating a runtime error
  /// when a final field is initialized twice. The constructor is expected to
  /// accept a single argument which is the name of the field.
  Builder getDuplicatedFieldInitializerError(Loader loader) {
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
  Builder getNativeAnnotation(Loader loader) {
    if (cachedNativeAnnotation != null) return cachedNativeAnnotation;
    LibraryBuilder internal = loader.read(Uri.parse("dart:_internal"), -1);
    return cachedNativeAnnotation = internal.getConstructor("ExternalName");
  }

  void loadExtraRequiredLibraries(Loader loader) {
    for (String uri in backendTarget.extraRequiredLibraries) {
      loader.read(Uri.parse(uri), -1);
    }
  }

  void addSourceInformation(
      Uri uri, List<int> lineStarts, List<int> sourceCode);

  void readPatchFiles(covariant LibraryBuilder library) {}
}
