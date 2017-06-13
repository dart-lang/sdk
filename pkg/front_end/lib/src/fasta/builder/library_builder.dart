// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.library_builder;

import '../combinator.dart' show Combinator;

import '../errors.dart' show internalError;

import '../export.dart' show Export;

import '../loader.dart' show Loader;

import '../messages.dart' show nit, warning;

import '../util/relativize.dart' show relativizeUri;

import 'builder.dart'
    show
        Builder,
        ClassBuilder,
        DynamicTypeBuilder,
        PrefixBuilder,
        Scope,
        ScopeBuilder,
        TypeBuilder,
        VoidTypeBuilder;

abstract class LibraryBuilder<T extends TypeBuilder, R> extends Builder {
  final Scope scope;

  final Scope exports;

  final ScopeBuilder scopeBuilder;

  final ScopeBuilder exportScopeBuilder;

  final List<Export> exporters = <Export>[];

  final Uri fileUri;

  final String relativeFileUri;

  LibraryBuilder partOfLibrary;

  /// True if a compile-time error has been reported in this library.
  bool hasCompileTimeErrors = false;

  LibraryBuilder(Uri fileUri, this.scope, this.exports)
      : fileUri = fileUri,
        relativeFileUri = relativizeUri(fileUri),
        scopeBuilder = new ScopeBuilder(scope),
        exportScopeBuilder = new ScopeBuilder(exports),
        super(null, -1, fileUri);

  Loader get loader;

  Uri get uri;

  Builder addBuilder(String name, Builder builder, int charOffset);

  void addExporter(
      LibraryBuilder exporter, List<Combinator> combinators, int charOffset) {
    exporters.add(new Export(exporter, this, combinators, charOffset));
  }

  /// See `Loader.addCompileTimeError` for an explanation of the arguments
  /// passed to this method.
  ///
  /// If [fileUri] is null, it defaults to `this.fileUri`.
  void addCompileTimeError(int charOffset, Object message,
      {Uri fileUri, bool silent: false, bool wasHandled: false}) {
    hasCompileTimeErrors = true;
    loader.addCompileTimeError(fileUri ?? this.fileUri, charOffset, message,
        silent: silent, wasHandled: wasHandled);
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

  /// Returns true if the export scope was modified.
  bool addToExportScope(String name, Builder member) {
    if (name.startsWith("_")) return false;
    if (member is PrefixBuilder) return false;
    Map<String, Builder> map =
        member.isSetter ? exports.setters : exports.local;
    Builder existing = map[name];
    if (existing == member) return false;
    if (existing != null) {
      Builder result =
          buildAmbiguousBuilder(name, existing, member, -1, isExport: true);
      map[name] = result;
      return result != existing;
    } else {
      map[name] = member;
    }
    return true;
  }

  void addToScope(String name, Builder member, int charOffset, bool isImport);

  Builder buildAmbiguousBuilder(
      String name, Builder builder, Builder other, int charOffset,
      {bool isExport: false, bool isImport: false});

  int finishStaticInvocations() => 0;

  int finishNativeMethods() => 0;

  /// Looks up [constructorName] in the class named [className].
  ///
  /// The class is looked up in this library's export scope unless
  /// [bypassLibraryPrivacy] is true, in which case it is looked up in the
  /// library scope of this library.
  ///
  /// It is an error if no such class is found, or if the class doesn't have a
  /// matching constructor (or factory).
  ///
  /// If [constructorName] is null or the empty string, it's assumed to be an
  /// unnamed constructor. it's an error if [constructorName] starts with
  /// `"_"`, and [bypassLibraryPrivacy] is false.
  Builder getConstructor(String className,
      {String constructorName, bool bypassLibraryPrivacy: false}) {
    constructorName ??= "";
    if (constructorName.startsWith("_") && !bypassLibraryPrivacy) {
      throw internalError("Internal error: Can't access private constructor "
          "'$constructorName'.");
    }
    Builder cls =
        (bypassLibraryPrivacy ? scope : exports).lookup(className, -1, null);
    if (cls is ClassBuilder) {
      // TODO(ahe): This code is similar to code in `endNewExpression` in
      // `body_builder.dart`, try to share it.
      Builder constructor =
          cls.findConstructorOrFactory(constructorName, -1, null, this);
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

  void forEach(void f(String name, Builder builder)) {
    scope.forEach(f);
  }

  /// Don't use for scope lookup. Only use when an element is known to exist
  /// (and not a setter).
  Builder operator [](String name) {
    return scope.local[name] ?? internalError("Not found: '$name'.");
  }

  Builder lookup(String name, int charOffset, Uri fileUri) {
    return scope.lookup(name, charOffset, fileUri);
  }
}
