// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.library_builder;

import '../combinator.dart' show Combinator;

import '../errors.dart' show InputError, internalError, printUnexpected;

import '../export.dart' show Export;

import '../loader.dart' show Loader;

import '../messages.dart' show nit, warning;

import '../util/relativize.dart' show relativizeUri;

import 'builder.dart'
    show
        Builder,
        DynamicTypeBuilder,
        ClassBuilder,
        TypeBuilder,
        VoidTypeBuilder;

import 'scope.dart' show Scope;

abstract class LibraryBuilder<T extends TypeBuilder, R> extends Builder {
  final List<Export> exporters = <Export>[];

  final List<InputError> compileTimeErrors = <InputError>[];

  LibraryBuilder partOfLibrary;

  Loader get loader;

  Uri get uri;

  final Uri fileUri;
  final String relativeFileUri;

  Map<String, Builder> get members;

  // TODO(ahe): Move this to SourceLibraryBuilder.
  Scope get scope;

  Map<String, Builder> get exports;

  LibraryBuilder(Uri fileUri)
      : fileUri = fileUri,
        relativeFileUri = relativizeUri(fileUri),
        super(null, -1, fileUri);

  Builder addBuilder(String name, Builder builder, int charOffset);

  void addExporter(
      LibraryBuilder exporter, List<Combinator> combinators, int charOffset) {
    exporters.add(new Export(exporter, this, combinators, charOffset));
  }

  void addCompileTimeError(int charOffset, Object message,
      {Uri fileUri, bool silent: false}) {
    fileUri ??= this.fileUri;
    if (!silent) {
      printUnexpected(fileUri, charOffset, message);
    }
    compileTimeErrors.add(new InputError(fileUri, charOffset, message));
  }

  void addWarning(int charOffset, Object message,
      {Uri fileUri, bool silent: false}) {
    fileUri ??= this.fileUri;
    if (!silent) {
      warning(fileUri, charOffset, message);
    }
  }

  void addNit(int charOffset, Object message,
      {Uri fileUri, bool silent: false}) {
    fileUri ??= this.fileUri;
    if (!silent) {
      nit(fileUri, charOffset, message);
    }
  }

  bool addToExportScope(String name, Builder member);

  void addToScope(String name, Builder member, int charOffset, bool isImport);

  Builder buildAmbiguousBuilder(
      String name, Builder builder, Builder other, int charOffset,
      {bool isExport: false, bool isImport: false});

  int finishStaticInvocations() => 0;

  int finishNativeMethods() => 0;

  /// Looks up [constructorName] in the class named [className]. It's an error
  /// if no such class is exported by this library, or if the class doesn't
  /// have a matching constructor (or factory).
  ///
  /// If [constructorName] is null or the empty string, it's assumed to be an
  /// unnamed constructor.
  Builder getConstructor(String className,
      {String constructorName, bool isPrivate: false}) {
    constructorName ??= "";
    Builder cls = (isPrivate ? members : exports)[className];
    if (cls is ClassBuilder) {
      // TODO(ahe): This code is similar to code in `endNewExpression` in
      // `body_builder.dart`, try to share it.
      Builder constructor = cls.findConstructorOrFactory(constructorName);
      if (constructor == null) {
        // Fall-through to internal error below.
      } else if (constructor.isConstructor) {
        if (!cls.isAbstract) {
          return constructor;
        }
      } else if (constructor.isFactory) {
        return constructor;
      }
    }
    throw internalError("Internal error: No constructor named"
        " '$className::$constructorName' in '$uri'.");
  }

  int finishTypeVariables(ClassBuilder object) => 0;

  void becomeCoreLibrary(dynamicType, voidType) {
    addBuilder("dynamic",
        new DynamicTypeBuilder<T, dynamic>(dynamicType, this, -1), -1);
    addBuilder("void", new VoidTypeBuilder<T, dynamic>(voidType, this, -1), -1);
  }
}
