// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_library_builder;

import 'package:kernel/ast.dart' show ProcedureKind;

import '../../base/resolve_relative_uri.dart' show resolveRelativeUri;

import '../../base/instrumentation.dart' show Instrumentation;

import '../../scanner/token.dart' show Token;

import '../builder/builder.dart'
    show
        ClassBuilder,
        ConstructorReferenceBuilder,
        Declaration,
        FormalParameterBuilder,
        FunctionTypeBuilder,
        LibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        PrefixBuilder,
        ProcedureBuilder,
        QualifiedName,
        Scope,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder,
        UnresolvedType;

import '../combinator.dart' show Combinator;

import '../deprecated_problems.dart' show deprecated_inputError;

import '../export.dart' show Export;

import '../fasta_codes.dart'
    show
        messageConstructorWithWrongName,
        messageExpectedUri,
        messageMemberWithSameNameAsClass,
        messagePartOfSelf,
        messagePartOfTwoLibraries,
        messagePartOfTwoLibrariesContext,
        noLength,
        templateConflictsWithMember,
        templateConflictsWithSetter,
        templateCouldNotParseUri,
        templateDeferredPrefixDuplicated,
        templateDeferredPrefixDuplicatedCause,
        templateDuplicatedDefinition,
        templateConstructorWithWrongNameContext,
        templateMissingPartOf,
        templatePartOfLibraryNameMismatch,
        templatePartOfUriMismatch,
        templatePartOfUseUri,
        templatePartTwice;

import '../import.dart' show Import;

import '../configuration.dart' show Configuration;

import '../problems.dart' show unhandled;

import 'source_loader.dart' show SourceLoader;

abstract class SourceLibraryBuilder<T extends TypeBuilder, R>
    extends LibraryBuilder<T, R> {
  static const String MALFORMED_URI_SCHEME = "org-dartlang-malformed-uri";

  final SourceLoader loader;

  final DeclarationBuilder<T> libraryDeclaration;

  final List<ConstructorReferenceBuilder> constructorReferences =
      <ConstructorReferenceBuilder>[];

  final List<SourceLibraryBuilder<T, R>> parts = <SourceLibraryBuilder<T, R>>[];

  final List<Import> imports = <Import>[];

  final List<Export> exports = <Export>[];

  final Scope importScope;

  final Uri fileUri;

  final List<List> implementationBuilders = <List<List>>[];

  /// Indicates whether type inference (and type promotion) should be disabled
  /// for this library.
  @override
  final bool disableTypeInference;

  String documentationComment;

  String name;

  String partOfName;

  Uri partOfUri;

  List<MetadataBuilder> metadata;

  /// The current declaration that is being built. When we start parsing a
  /// declaration (class, method, and so on), we don't have enough information
  /// to create a builder and this object records its members and types until,
  /// for example, [addClass] is called.
  DeclarationBuilder<T> currentDeclaration;

  bool canAddImplementationBuilders = false;

  SourceLibraryBuilder(SourceLoader loader, Uri fileUri, Scope scope)
      : this.fromScopes(loader, fileUri, new DeclarationBuilder<T>.library(),
            scope ?? new Scope.top());

  SourceLibraryBuilder.fromScopes(
      this.loader, this.fileUri, this.libraryDeclaration, this.importScope)
      : disableTypeInference = loader.target.disableTypeInference,
        currentDeclaration = libraryDeclaration,
        super(
            fileUri, libraryDeclaration.toScope(importScope), new Scope.top());

  Uri get uri;

  @override
  bool get isPart => partOfName != null || partOfUri != null;

  List<UnresolvedType<T>> get types => libraryDeclaration.types;

  T addNamedType(Object name, List<T> arguments, int charOffset);

  T addMixinApplication(T supertype, List<T> mixins, int charOffset);

  T addType(T type, int charOffset) {
    currentDeclaration
        .addType(new UnresolvedType<T>(type, charOffset, fileUri));
    return type;
  }

  T addVoidType(int charOffset);

  ConstructorReferenceBuilder addConstructorReference(
      Object name, List<T> typeArguments, String suffix, int charOffset) {
    ConstructorReferenceBuilder ref = new ConstructorReferenceBuilder(
        name, typeArguments, suffix, this, charOffset);
    constructorReferences.add(ref);
    return ref;
  }

  void beginNestedDeclaration(String name, {bool hasMembers: true}) {
    currentDeclaration = currentDeclaration.createNested(name, hasMembers);
  }

  DeclarationBuilder<T> endNestedDeclaration(String name) {
    assert(
        (name?.startsWith(currentDeclaration.name) ??
                (name == currentDeclaration.name)) ||
            currentDeclaration.name == "operator",
        "${name} != ${currentDeclaration.name}");
    DeclarationBuilder<T> previous = currentDeclaration;
    currentDeclaration = currentDeclaration.parent;
    return previous;
  }

  bool uriIsValid(Uri uri) => uri.scheme != MALFORMED_URI_SCHEME;

  Uri resolve(Uri baseUri, String uri, int uriOffset, {isPart: false}) {
    if (uri == null) {
      addCompileTimeError(messageExpectedUri, uriOffset, noLength, this.uri);
      return new Uri(scheme: MALFORMED_URI_SCHEME);
    }
    Uri parsedUri;
    try {
      parsedUri = Uri.parse(uri);
    } on FormatException catch (e) {
      // Point to position in string indicated by the exception,
      // or to the initial quote if no position is given.
      // (Assumes the directive is using a single-line string.)
      addCompileTimeError(
          templateCouldNotParseUri.withArguments(uri, e.message),
          uriOffset + 1 + (e.offset ?? -1),
          1,
          this.uri);
      return new Uri(
          scheme: MALFORMED_URI_SCHEME, query: Uri.encodeQueryComponent(uri));
    }
    if (isPart && baseUri.scheme == "dart") {
      // Resolve using special rules for dart: URIs
      return resolveRelativeUri(baseUri, parsedUri);
    } else {
      return baseUri.resolveUri(parsedUri);
    }
  }

  String computeAndValidateConstructorName(Object name, int charOffset,
      {isFactory: false}) {
    String className = currentDeclaration.name;
    String prefix;
    String suffix;
    if (name is QualifiedName) {
      prefix = name.prefix;
      suffix = name.suffix;
    } else {
      prefix = name;
      suffix = null;
    }
    if (prefix == className) {
      return suffix ?? "";
    }
    if (suffix == null && !isFactory) {
      // A legal name for a regular method, but not for a constructor.
      return null;
    }

    addProblem(
        messageConstructorWithWrongName, charOffset, prefix.length, fileUri,
        context: [
          templateConstructorWithWrongNameContext
              .withArguments(currentDeclaration.name)
              .withLocation(uri, currentDeclaration.charOffset,
                  currentDeclaration.name.length)
        ]);

    return suffix;
  }

  void addExport(
      List<MetadataBuilder> metadata,
      String uri,
      List<Configuration> configurations,
      List<Combinator> combinators,
      int charOffset,
      int uriOffset) {
    if (configurations != null) {
      for (Configuration config in configurations) {
        if (lookupImportCondition(config.dottedName) == config.condition) {
          uri = config.importUri;
          break;
        }
      }
    }

    var exportedLibrary = loader
        .read(resolve(this.uri, uri, uriOffset), charOffset, accessor: this);
    exportedLibrary.addExporter(this, combinators, charOffset);
    exports.add(new Export(this, exportedLibrary, combinators, charOffset));
  }

  String lookupImportCondition(String dottedName) {
    const String prefix = "dart.library.";
    if (!dottedName.startsWith(prefix)) return "";
    dottedName = dottedName.substring(prefix.length);
    if (!loader.target.uriTranslator.isLibrarySupported(dottedName)) return "";

    LibraryBuilder imported =
        loader.builders[new Uri(scheme: "dart", path: dottedName)];

    if (imported == null) {
      LibraryBuilder coreLibrary = loader.read(
          resolve(
              this.uri, new Uri(scheme: "dart", path: "core").toString(), -1),
          -1);
      imported = coreLibrary
          .loader.builders[new Uri(scheme: 'dart', path: dottedName)];
    }
    return imported != null ? "true" : "";
  }

  void addImport(
      List<MetadataBuilder> metadata,
      String uri,
      List<Configuration> configurations,
      String prefix,
      List<Combinator> combinators,
      bool deferred,
      int charOffset,
      int prefixCharOffset,
      int uriOffset,
      int importIndex) {
    if (configurations != null) {
      for (Configuration config in configurations) {
        if (lookupImportCondition(config.dottedName) == config.condition) {
          uri = config.importUri;
          break;
        }
      }
    }

    LibraryBuilder builder = null;

    Uri resolvedUri;
    String nativePath;
    const String nativeExtensionScheme = "dart-ext:";
    if (uri.startsWith(nativeExtensionScheme)) {
      String strippedUri = uri.substring(nativeExtensionScheme.length);
      if (strippedUri.startsWith("package")) {
        resolvedUri = resolve(
            this.uri, strippedUri, uriOffset + nativeExtensionScheme.length);
        resolvedUri = loader.target.translateUri(resolvedUri);
        nativePath = resolvedUri.toString();
      } else {
        resolvedUri = new Uri(scheme: "dart-ext", pathSegments: [uri]);
        nativePath = uri;
      }
    } else {
      resolvedUri = resolve(this.uri, uri, uriOffset);
      builder = loader.read(resolvedUri, charOffset, accessor: this);
    }

    imports.add(new Import(this, builder, deferred, prefix, combinators,
        configurations, charOffset, prefixCharOffset, importIndex,
        nativeImportPath: nativePath));
  }

  void addPart(List<MetadataBuilder> metadata, String uri, int charOffset) {
    Uri resolvedUri;
    Uri newFileUri;
    resolvedUri = resolve(this.uri, uri, charOffset, isPart: true);
    newFileUri = resolve(fileUri, uri, charOffset);
    parts.add(loader.read(resolvedUri, charOffset,
        fileUri: newFileUri, accessor: this));
  }

  void addPartOf(
      List<MetadataBuilder> metadata, String name, String uri, int uriOffset) {
    partOfName = name;
    if (uri != null) {
      partOfUri = resolve(this.uri, uri, uriOffset);
    }
  }

  void addClass(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      String name,
      List<TypeVariableBuilder> typeVariables,
      T supertype,
      List<T> interfaces,
      int startCharOffset,
      int charOffset,
      int charEndOffset,
      int supertypeOffset,
      int codeStartOffset,
      int codeEndOffset);

  void addNamedMixinApplication(
      String documentationComment,
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      int modifiers,
      T mixinApplication,
      List<T> interfaces,
      int charOffset,
      int codeStartOffset,
      int codeEndOffset);

  void addField(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      T type,
      String name,
      int charOffset,
      Token initializerTokenForInference,
      bool hasInitializer);

  void addFields(String documentationComment, List<MetadataBuilder> metadata,
      int modifiers, T type, List<Object> fieldsInfo) {
    for (int i = 0; i < fieldsInfo.length; i += 4) {
      String name = fieldsInfo[i];
      int charOffset = fieldsInfo[i + 1];
      bool hasInitializer = fieldsInfo[i + 2] != null;
      Token initializerTokenForInference =
          type == null ? fieldsInfo[i + 2] : null;
      if (initializerTokenForInference != null) {
        Token beforeLast = fieldsInfo[i + 3];
        beforeLast.setNext(new Token.eof(beforeLast.next.offset));
      }
      addField(documentationComment, metadata, modifiers, type, name,
          charOffset, initializerTokenForInference, hasInitializer);
    }
  }

  void addConstructor(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      T returnType,
      final Object name,
      String constructorName,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName);

  void addProcedure(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      T returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      ProcedureKind kind,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName,
      int codeStartOffset,
      int codeEndOffset,
      {bool isTopLevel});

  void addEnum(
      String documentationComment,
      List<MetadataBuilder> metadata,
      String name,
      List<Object> constantNamesAndOffsets,
      int charOffset,
      int charEndOffset);

  void addFunctionTypeAlias(
      String documentationComment,
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      FunctionTypeBuilder type,
      int charOffset);

  FunctionTypeBuilder addFunctionType(
      T returnType,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      int charOffset);

  void addFactoryMethod(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      Object name,
      List<FormalParameterBuilder> formals,
      ConstructorReferenceBuilder redirectionTarget,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName);

  FormalParameterBuilder addFormalParameter(List<MetadataBuilder> metadata,
      int modifiers, T type, String name, bool hasThis, int charOffset);

  TypeVariableBuilder addTypeVariable(String name, T bound, int charOffset);

  Declaration addBuilder(String name, Declaration declaration, int charOffset) {
    // TODO(ahe): Set the parent correctly here. Could then change the
    // implementation of MemberBuilder.isTopLevel to test explicitly for a
    // LibraryBuilder.
    if (currentDeclaration == libraryDeclaration) {
      if (declaration is MemberBuilder) {
        declaration.parent = this;
      } else if (declaration is TypeDeclarationBuilder) {
        declaration.parent = this;
      } else if (declaration is PrefixBuilder) {
        assert(declaration.parent == this);
      } else {
        return unhandled(
            "${declaration.runtimeType}", "addBuilder", charOffset, fileUri);
      }
    } else {
      assert(currentDeclaration.parent == libraryDeclaration);
    }
    bool isConstructor = declaration is ProcedureBuilder &&
        (declaration.isConstructor || declaration.isFactory);
    if (!isConstructor &&
        !declaration.isSetter &&
        name == currentDeclaration.name) {
      addCompileTimeError(
          messageMemberWithSameNameAsClass, charOffset, noLength, fileUri);
    }
    Map<String, Declaration> members = isConstructor
        ? currentDeclaration.constructors
        : (declaration.isSetter
            ? currentDeclaration.setters
            : currentDeclaration.members);
    Declaration existing = members[name];
    declaration.next = existing;
    if (declaration is PrefixBuilder && existing is PrefixBuilder) {
      assert(existing.next == null);
      Declaration deferred;
      Declaration other;
      if (declaration.deferred) {
        deferred = declaration;
        other = existing;
      } else if (existing.deferred) {
        deferred = existing;
        other = declaration;
      }
      if (deferred != null) {
        addCompileTimeError(
            templateDeferredPrefixDuplicated.withArguments(name),
            deferred.charOffset,
            noLength,
            fileUri,
            context: [
              templateDeferredPrefixDuplicatedCause
                  .withArguments(name)
                  .withLocation(fileUri, other.charOffset, noLength)
            ]);
      }
      return existing
        ..exportScope.merge(declaration.exportScope,
            (String name, Declaration existing, Declaration member) {
          return computeAmbiguousDeclaration(
              name, existing, member, charOffset);
        });
    } else if (isDuplicatedDefinition(existing, declaration)) {
      addCompileTimeError(templateDuplicatedDefinition.withArguments(name),
          charOffset, noLength, fileUri);
    }
    return members[name] = declaration;
  }

  bool isDuplicatedDefinition(Declaration existing, Declaration other) {
    if (existing == null) return false;
    Declaration next = existing.next;
    if (next == null) {
      if (existing.isGetter && other.isSetter) return false;
      if (existing.isSetter && other.isGetter) return false;
    } else {
      if (next is ClassBuilder && !next.isMixinApplication) return true;
    }
    if (existing is ClassBuilder && other is ClassBuilder) {
      // We allow multiple mixin applications with the same name. An
      // alternative is to share these mixin applications. This situation can
      // happen if you have `class A extends Object with Mixin {}` and `class B
      // extends Object with Mixin {}` in the same library.
      return !existing.isMixinApplication || !other.isMixinApplication;
    }
    return true;
  }

  void buildBuilder(Declaration declaration, LibraryBuilder coreLibrary);

  R build(LibraryBuilder coreLibrary) {
    assert(implementationBuilders.isEmpty);
    canAddImplementationBuilders = true;
    forEach((String name, Declaration declaration) {
      do {
        buildBuilder(declaration, coreLibrary);
        declaration = declaration.next;
      } while (declaration != null);
    });
    for (List list in implementationBuilders) {
      String name = list[0];
      Declaration declaration = list[1];
      int charOffset = list[2];
      addBuilder(name, declaration, charOffset);
      buildBuilder(declaration, coreLibrary);
    }
    canAddImplementationBuilders = false;

    scope.setters.forEach((String name, Declaration setter) {
      Declaration member = scopeBuilder[name];
      if (member == null || !member.isField || member.isFinal) return;
      addCompileTimeError(templateConflictsWithMember.withArguments(name),
          setter.charOffset, noLength, fileUri);
      // TODO(ahe): Context to previous message?
      addCompileTimeError(templateConflictsWithSetter.withArguments(name),
          member.charOffset, noLength, fileUri);
    });

    return null;
  }

  /// Used to add implementation builder during the call to [build] above.
  /// Currently, only anonymous mixins are using implementation builders (see
  /// [KernelMixinApplicationBuilder]
  /// (../kernel/kernel_mixin_application_builder.dart)).
  void addImplementationBuilder(
      String name, Declaration declaration, int charOffset) {
    assert(canAddImplementationBuilders, "$uri");
    implementationBuilders.add([name, declaration, charOffset]);
  }

  void validatePart() {
    if (parts.isNotEmpty) {
      deprecated_inputError(fileUri, -1,
          "A file that's a part of a library can't have parts itself.");
    }
    if (exporters.isNotEmpty) {
      Export export = exporters.first;
      deprecated_inputError(
          export.fileUri, export.charOffset, "A part can't be exported.");
    }
  }

  void includeParts() {
    Set<Uri> seenParts = new Set<Uri>();
    for (SourceLibraryBuilder<T, R> part in parts) {
      if (part == this) {
        addCompileTimeError(messagePartOfSelf, -1, noLength, fileUri);
      } else if (seenParts.add(part.fileUri)) {
        if (part.partOfLibrary != null) {
          addProblem(messagePartOfTwoLibraries, -1, noLength, part.fileUri,
              context: [
                messagePartOfTwoLibrariesContext.withLocation(
                    part.partOfLibrary.fileUri, -1, noLength),
                messagePartOfTwoLibrariesContext.withLocation(
                    this.fileUri, -1, noLength)
              ]);
        } else {
          includePart(part);
        }
      } else {
        addCompileTimeError(templatePartTwice.withArguments(part.fileUri), -1,
            noLength, fileUri);
      }
    }
  }

  void includePart(SourceLibraryBuilder<T, R> part) {
    if (part.partOfUri != null) {
      if (uriIsValid(part.partOfUri) && part.partOfUri != uri) {
        // This is a warning, but the part is still included.
        addProblem(
            templatePartOfUriMismatch.withArguments(
                part.fileUri, uri, part.partOfUri),
            -1,
            noLength,
            fileUri);
      }
    } else if (part.partOfName != null) {
      if (name != null) {
        if (part.partOfName != name) {
          // This is a warning, but the part is still included.
          addProblem(
              templatePartOfLibraryNameMismatch.withArguments(
                  part.fileUri, name, part.partOfName),
              -1,
              noLength,
              fileUri);
        }
      } else {
        // This is a warning, but the part is still included.
        addProblem(
            templatePartOfUseUri.withArguments(
                part.fileUri, fileUri, part.partOfName),
            -1,
            noLength,
            fileUri);
      }
    } else {
      // This is an error, but the part is still included, so that
      // metadata annotations can be associated with it.
      assert(!part.isPart);
      if (uriIsValid(part.fileUri)) {
        addCompileTimeError(templateMissingPartOf.withArguments(part.fileUri),
            -1, noLength, fileUri);
      }
    }
    part.forEach((String name, Declaration declaration) {
      if (declaration.next != null) {
        // TODO(ahe): This shouldn't be necessary as setters have been added to
        // their own scope.
        assert(declaration.next.next == null);
        addBuilder(name, declaration.next, declaration.next.charOffset);
      }
      addBuilder(name, declaration, declaration.charOffset);
    });
    types.addAll(part.types);
    constructorReferences.addAll(part.constructorReferences);
    part.partOfLibrary = this;
    part.scope.becomePartOf(scope);
    // TODO(ahe): Include metadata from part?
  }

  void buildInitialScopes() {
    forEach(addToExportScope);
  }

  void addImportsToScope() {
    bool explicitCoreImport = this == loader.coreLibrary;
    for (Import import in imports) {
      if (import.imported == loader.coreLibrary) {
        explicitCoreImport = true;
      }
      import.finalizeImports(this);
    }
    if (!explicitCoreImport) {
      loader.coreLibrary.exportScope.forEach((String name, Declaration member) {
        addToScope(name, member, -1, true);
      });
    }
  }

  @override
  void addToScope(
      String name, Declaration member, int charOffset, bool isImport) {
    Map<String, Declaration> map =
        member.isSetter ? importScope.setters : importScope.local;
    Declaration existing = map[name];
    if (existing != null) {
      if (existing != member) {
        map[name] = computeAmbiguousDeclaration(
            name, existing, member, charOffset,
            isImport: isImport);
      }
    } else {
      map[name] = member;
    }
  }

  /// Resolves all unresolved types in [types]. The list of types is cleared
  /// when done.
  int resolveTypes() {
    int typeCount = types.length;
    for (UnresolvedType<T> t in types) {
      t.resolveIn(scope, this);
      if (loader.target.strongMode) {
        t.checkType();
      } else {
        t.normalizeType();
      }
    }
    types.clear();
    return typeCount;
  }

  @override
  int resolveConstructors(_) {
    int count = 0;
    forEach((String name, Declaration member) {
      count += member.resolveConstructors(this);
    });
    return count;
  }

  List<TypeVariableBuilder> copyTypeVariables(
      List<TypeVariableBuilder> original, DeclarationBuilder declaration);

  @override
  String get fullNameForErrors {
    // TODO(ahe): Consider if we should use relativizeUri here. The downside to
    // doing that is that this URI may be used in an error message. Ideally, we
    // should create a class that represents qualified names that we can
    // relativize when printing a message, but still store the full URI in
    // .dill files.
    return name ?? "<library '$fileUri'>";
  }

  @override
  void instrumentTopLevelInference(Instrumentation instrumentation) {
    forEach((String name, Declaration member) {
      member.instrumentTopLevelInference(instrumentation);
    });
  }
}

/// Unlike [Scope], this scope is used during construction of builders to
/// ensure types and members are added to and resolved in the correct location.
class DeclarationBuilder<T extends TypeBuilder> {
  final DeclarationBuilder<T> parent;

  final Map<String, Declaration> members;

  final Map<String, Declaration> constructors;

  final Map<String, Declaration> setters;

  final List<UnresolvedType<T>> types = <UnresolvedType<T>>[];

  String name;

  // Offset of name token, updated by the outline builder along
  // with the name as the current declaration changes.
  int charOffset;

  List<TypeVariableBuilder> typeVariables;

  DeclarationBuilder(this.members, this.setters, this.constructors, this.name,
      this.charOffset, this.parent) {
    assert(name != null);
  }

  DeclarationBuilder.library()
      : this(<String, Declaration>{}, <String, Declaration>{}, null,
            "<library>", -1, null);

  DeclarationBuilder createNested(String name, bool hasMembers) {
    return new DeclarationBuilder<T>(
        hasMembers ? <String, MemberBuilder>{} : null,
        hasMembers ? <String, MemberBuilder>{} : null,
        hasMembers ? <String, MemberBuilder>{} : null,
        name,
        -1,
        this);
  }

  void addType(UnresolvedType<T> type) {
    types.add(type);
  }

  /// Resolves type variables in [types] and propagate other types to [parent].
  void resolveTypes(
      List<TypeVariableBuilder> typeVariables, SourceLibraryBuilder library) {
    // TODO(ahe): The input to this method, [typeVariables], shouldn't be just
    // type variables. It should be everything that's in scope, for example,
    // members (of a class) or formal parameters (of a method).
    // Also, this doesn't work well with patching.
    if (typeVariables == null) {
      // If there are no type variables in the scope, propagate our types to be
      // resolved in the parent declaration.
      parent.types.addAll(types);
    } else {
      Map<String, TypeVariableBuilder> map = <String, TypeVariableBuilder>{};
      for (TypeVariableBuilder builder in typeVariables) {
        map[builder.name] = builder;
      }
      for (UnresolvedType<T> type in types) {
        Object nameOrQualified = type.builder.name;
        String name = nameOrQualified is QualifiedName
            ? nameOrQualified.prefix
            : nameOrQualified;
        TypeVariableBuilder builder;
        if (name != null) {
          builder = map[name];
        }
        if (builder == null) {
          // Since name didn't resolve in this scope, propagate it to the
          // parent declaration.
          parent.addType(type);
        } else if (nameOrQualified is QualifiedName) {
          // Attempt to use type variable as prefix.
          type.builder.bind(
              type.builder.buildInvalidType(type.charOffset, type.fileUri));
        } else {
          type.builder.bind(builder);
        }
      }
    }
    types.clear();
  }

  Scope toScope(Scope parent) {
    return new Scope(members, setters, parent, name, isModifiable: false);
  }
}
