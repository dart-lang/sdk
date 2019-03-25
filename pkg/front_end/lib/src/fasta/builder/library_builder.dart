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
        FormattedMessage,
        LocatedMessage,
        Message,
        templateInternalProblemConstructorNotFound,
        templateInternalProblemNotFoundIn,
        templateInternalProblemPrivateConstructorAccess;

import '../severity.dart' show Severity;

import 'builder.dart'
    show
        ClassBuilder,
        Declaration,
        ModifierBuilder,
        NameIterator,
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

  bool get legacyMode => false;

  bool get isSynthetic => false;

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

  Uri get uri;

  Iterator<Declaration> get iterator {
    return LibraryLocalDeclarationIterator(this);
  }

  NameIterator get nameIterator {
    return new LibraryLocalDeclarationNameIterator(this);
  }

  Declaration addBuilder(String name, Declaration declaration, int charOffset);

  void addExporter(
      LibraryBuilder exporter, List<Combinator> combinators, int charOffset) {
    exporters.add(new Export(exporter, this, combinators, charOffset));
  }

  /// Add a problem with a severity determined by the severity of the message.
  ///
  /// If [fileUri] is null, it defaults to `this.fileUri`.
  ///
  /// See `Loader.addMessage` for an explanation of the
  /// arguments passed to this method.
  FormattedMessage addProblem(
      Message message, int charOffset, int length, Uri fileUri,
      {bool wasHandled: false,
      List<LocatedMessage> context,
      Severity severity,
      bool problemOnLibrary: false}) {
    fileUri ??= this.fileUri;

    return loader.addProblem(message, charOffset, length, fileUri,
        wasHandled: wasHandled,
        context: context,
        severity: severity,
        problemOnLibrary: true);
  }

  /// Returns true if the export scope was modified.
  bool addToExportScope(String name, Declaration member,
      [int charOffset = -1]) {
    if (name.startsWith("_")) return false;
    if (member is PrefixBuilder) return false;
    Map<String, Declaration> map =
        member.isSetter ? exportScope.setters : exportScope.local;
    Declaration existing = map[name];
    if (existing == member) return false;
    if (existing != null) {
      Declaration result = computeAmbiguousDeclaration(
          name, existing, member, charOffset,
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
            "$className.$constructorName", uri),
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

  void becomeCoreLibrary() {
    if (scope.local["dynamic"] == null) {
      addSyntheticDeclarationOfDynamic();
    }
  }

  void addSyntheticDeclarationOfDynamic();

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

  void recordAccess(int charOffset, int length, Uri fileUri) {}
}

class LibraryLocalDeclarationIterator implements Iterator<Declaration> {
  final LibraryBuilder library;
  final Iterator<Declaration> iterator;

  LibraryLocalDeclarationIterator(this.library)
      : iterator = library.scope.iterator;

  Declaration get current => iterator.current;

  bool moveNext() {
    while (iterator.moveNext()) {
      if (current.parent == library) return true;
    }
    return false;
  }
}

class LibraryLocalDeclarationNameIterator implements NameIterator {
  final LibraryBuilder library;
  final NameIterator iterator;

  LibraryLocalDeclarationNameIterator(this.library)
      : iterator = library.scope.nameIterator;

  Declaration get current => iterator.current;

  String get name => iterator.name;

  bool moveNext() {
    while (iterator.moveNext()) {
      if (current.parent == library) return true;
    }
    return false;
  }
}
