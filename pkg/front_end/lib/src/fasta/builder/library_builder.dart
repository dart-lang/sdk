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
        templateInternalProblemConstructorNotFound,
        templateInternalProblemNotFoundIn,
        templateInternalProblemPrivateConstructorAccess;

import 'builder.dart'
    show
        ClassBuilder,
        Declaration,
        ModifierBuilder,
        PrefixBuilder,
        Scope,
        ScopeBuilder,
        TypeBuilder;

abstract class LibraryBuilder<T extends TypeBuilder, R>
    extends ModifierBuilder {
  final Scope scope;

  final Scope exportScope;

  final ScopeBuilder scopeBuilder;

  final ScopeBuilder exportScopeBuilder;

  final List<Export> exporters = <Export>[];

  LibraryBuilder partOfLibrary;

  bool mayImplementRestrictedTypes = false;

  LibraryBuilder(Uri fileUri, this.scope, this.exportScope)
      : scopeBuilder = new ScopeBuilder(scope),
        exportScopeBuilder = new ScopeBuilder(exportScope),
        super(null, -1, fileUri);

  @override
  Declaration get parent => null;

  bool get isPart => false;

  @override
  String get debugName => "LibraryBuilder";

  Loader get loader;

  @override
  int get modifiers => 0;

  @override
  R get target;

  bool get disableTypeInference => true;

  Uri get uri;

  Declaration addBuilder(String name, Declaration declaration, int charOffset);

  void addExporter(
      LibraryBuilder exporter, List<Combinator> combinators, int charOffset) {
    exporters.add(new Export(exporter, this, combinators, charOffset));
  }

  /// See `Loader.addCompileTimeError` for an explanation of the
  /// arguments passed to this method.
  ///
  /// If [fileUri] is null, it defaults to `this.fileUri`.
  void addCompileTimeError(
      Message message, int charOffset, int length, Uri fileUri,
      {bool wasHandled: false, List<LocatedMessage> context}) {
    fileUri ??= this.fileUri;
    loader.addCompileTimeError(message, charOffset, length, fileUri,
        wasHandled: wasHandled, context: context);
  }

  /// Add a problem with a severity determined by the severity of the message.
  void addProblem(Message message, int charOffset, int length, Uri fileUri,
      {List<LocatedMessage> context}) {
    fileUri ??= this.fileUri;
    loader.addProblem(message, charOffset, length, fileUri, context: context);
  }

  /// Returns true if the export scope was modified.
  bool addToExportScope(String name, Declaration member) {
    if (name.startsWith("_")) return false;
    if (member is PrefixBuilder) return false;
    Map<String, Declaration> map =
        member.isSetter ? exportScope.setters : exportScope.local;
    Declaration existing = map[name];
    if (existing == member) return false;
    if (existing != null) {
      Declaration result = computeAmbiguousDeclaration(
          name, existing, member, -1,
          isExport: true);
      map[name] = result;
      return result != existing;
    } else {
      map[name] = member;
    }
    return true;
  }

  void addToScope(
      String name, Declaration member, int charOffset, bool isImport);

  Declaration computeAmbiguousDeclaration(
      String name, Declaration declaration, Declaration other, int charOffset,
      {bool isExport: false, bool isImport: false});

  int finishDeferredLoadTearoffs() => 0;

  int finishForwarders() => 0;

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
  Declaration getConstructor(String className,
      {String constructorName, bool bypassLibraryPrivacy: false}) {
    constructorName ??= "";
    if (constructorName.startsWith("_") && !bypassLibraryPrivacy) {
      return internalProblem(
          templateInternalProblemPrivateConstructorAccess
              .withArguments(constructorName),
          -1,
          null);
    }
    Declaration cls = (bypassLibraryPrivacy ? scope : exportScope)
        .lookup(className, -1, null);
    if (cls is ClassBuilder) {
      // TODO(ahe): This code is similar to code in `endNewExpression` in
      // `body_builder.dart`, try to share it.
      Declaration constructor =
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

  int finishTypeVariables(ClassBuilder object, TypeBuilder dynamicType) => 0;

  /// This method instantiates type parameters to their bounds in some cases
  /// where they were omitted by the programmer and not provided by the type
  /// inference.  The method returns the number of distinct type variables
  /// that were instantiated in this library.
  int computeDefaultTypes(TypeBuilder dynamicType, TypeBuilder bottomType,
      ClassBuilder objectClass) {
    return 0;
  }

  void becomeCoreLibrary(dynamicType);

  void forEach(void f(String name, Declaration declaration)) {
    scope.forEach((String name, Declaration declaration) {
      if (declaration.parent == this) {
        f(name, declaration);
      }
    });
  }

  /// Don't use for scope lookup. Only use when an element is known to exist
  /// (and not a setter).
  Declaration operator [](String name) {
    return scope.local[name] ??
        internalProblem(
            templateInternalProblemNotFoundIn.withArguments(name, "$fileUri"),
            -1,
            fileUri);
  }

  Declaration lookup(String name, int charOffset, Uri fileUri) {
    return scope.lookup(name, charOffset, fileUri);
  }

  /// If this is a patch library, apply its patches to [origin].
  void applyPatches() {
    if (!isPatch) return;
    unsupported("${runtimeType}.applyPatches", -1, fileUri);
  }
}
