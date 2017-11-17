// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.library_builder;

import '../combinator.dart' show Combinator;

import '../problems.dart' show internalProblem, unsupported;

import '../export.dart' show Export;

import '../loader.dart' show Loader;

import '../messages.dart'
    show
        LocatedMessage,
        Message,
        error,
        nit,
        report,
        templateInternalProblemConstructorNotFound,
        templateInternalProblemNotFoundIn,
        templateInternalProblemPrivateConstructorAccess,
        warning;

import '../severity.dart' show Severity;

import 'builder.dart'
    show
        Builder,
        ClassBuilder,
        DynamicTypeBuilder,
        ModifierBuilder,
        PrefixBuilder,
        Scope,
        ScopeBuilder,
        TypeBuilder,
        VoidTypeBuilder;

abstract class LibraryBuilder<T extends TypeBuilder, R>
    extends ModifierBuilder {
  final Scope scope;

  final Scope exportScope;

  final ScopeBuilder scopeBuilder;

  final ScopeBuilder exportScopeBuilder;

  final List<Export> exporters = <Export>[];

  LibraryBuilder partOfLibrary;

  /// True if a compile-time error has been reported in this library.
  bool hasCompileTimeErrors = false;

  bool mayImplementRestrictedTypes = false;

  LibraryBuilder(Uri fileUri, this.scope, this.exportScope)
      : scopeBuilder = new ScopeBuilder(scope),
        exportScopeBuilder = new ScopeBuilder(exportScope),
        super(null, -1, fileUri);

  @override
  String get debugName => "LibraryBuilder";

  Loader get loader;

  @override
  int get modifiers => 0;

  @override
  R get target;

  Uri get uri;

  Builder addBuilder(String name, Builder builder, int charOffset);

  void addExporter(
      LibraryBuilder exporter, List<Combinator> combinators, int charOffset) {
    exporters.add(new Export(exporter, this, combinators, charOffset));
  }

  /// See `Loader.addCompileTimeError` for an explanation of the
  /// arguments passed to this method.
  ///
  /// If [fileUri] is null, it defaults to `this.fileUri`.
  void addCompileTimeError(Message message, int charOffset, Uri uri,
      {bool silent: false, bool wasHandled: false, LocatedMessage context}) {
    hasCompileTimeErrors = true;
    loader.addCompileTimeError(message, charOffset, uri,
        silent: silent, wasHandled: wasHandled, context: context);
  }

  void addWarning(Message message, int charOffset, Uri uri,
      {bool silent: false, LocatedMessage context}) {
    if (!silent) {
      warning(message, charOffset, uri);
      if (context != null) {
        report(context, Severity.warning);
      }
    }
  }

  void addError(Message message, int charOffset, Uri uri,
      {bool silent: false, LocatedMessage context}) {
    if (!silent) {
      error(message, charOffset, uri);
      if (context != null) {
        report(context, Severity.error);
      }
    }
  }

  void addNit(Message message, int charOffset, Uri uri, {bool silent: false}) {
    if (!silent) {
      nit(message, charOffset, uri);
    }
  }

  /// Returns true if the export scope was modified.
  bool addToExportScope(String name, Builder member) {
    if (name.startsWith("_")) return false;
    if (member is PrefixBuilder) return false;
    Map<String, Builder> map =
        member.isSetter ? exportScope.setters : exportScope.local;
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

  int finishDeferredLoadTearoffs() => 0;

  int finishStaticInvocations() => 0;

  int finishNativeMethods() => 0;

  int finishPatchMethods() => 0;

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
      return internalProblem(
          templateInternalProblemPrivateConstructorAccess
              .withArguments(constructorName),
          -1,
          null);
    }
    Builder cls = (bypassLibraryPrivacy ? scope : exportScope)
        .lookup(className, -1, null);
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
    throw internalProblem(
        templateInternalProblemConstructorNotFound.withArguments(
            "$className::$constructorName", uri),
        -1,
        null);
  }

  int finishTypeVariables(ClassBuilder object) => 0;

  void becomeCoreLibrary(dynamicType, voidType) {
    addBuilder("dynamic",
        new DynamicTypeBuilder<T, dynamic>(dynamicType, this, -1), -1);
    addBuilder("void", new VoidTypeBuilder<T, dynamic>(voidType, this, -1), -1);
  }

  void forEach(void f(String name, Builder builder)) {
    scope.forEach((String name, Builder builder) {
      if (builder.parent == this) {
        f(name, builder);
      }
    });
  }

  /// Don't use for scope lookup. Only use when an element is known to exist
  /// (and not a setter).
  Builder operator [](String name) {
    return scope.local[name] ??
        internalProblem(
            templateInternalProblemNotFoundIn.withArguments(
                name, relativeFileUri),
            -1,
            null);
  }

  Builder lookup(String name, int charOffset, Uri fileUri) {
    return scope.lookup(name, charOffset, fileUri);
  }

  /// If this is a patch library, apply its patches to [origin].
  void applyPatches() {
    if (!isPatch) return;
    unsupported("${runtimeType}.applyPatches", -1, fileUri);
  }
}
