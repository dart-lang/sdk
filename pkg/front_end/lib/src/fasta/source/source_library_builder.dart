// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_library_builder;

import 'package:kernel/ast.dart' show ProcedureKind;

import '../../base/resolve_relative_uri.dart' show resolveRelativeUri;

import '../../scanner/token.dart' show Token;

import '../builder/builder.dart'
    show
        ClassBuilder,
        ConstructorReferenceBuilder,
        Declaration,
        EnumConstantInfo,
        FormalParameterBuilder,
        FunctionTypeBuilder,
        LibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        NameIterator,
        PrefixBuilder,
        ProcedureBuilder,
        QualifiedName,
        Scope,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder,
        UnresolvedType,
        flattenName;

import '../combinator.dart' show Combinator;

import '../export.dart' show Export;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        messageConstructorWithWrongName,
        messageExpectedUri,
        messageMemberWithSameNameAsClass,
        messagePartExport,
        messagePartExportContext,
        messagePartInPart,
        messagePartInPartLibraryContext,
        messagePartOfSelf,
        messagePartOfTwoLibraries,
        messagePartOfTwoLibrariesContext,
        noLength,
        templateConflictsWithMember,
        templateConflictsWithSetter,
        templateConstructorWithWrongNameContext,
        templateCouldNotParseUri,
        templateDeferredPrefixDuplicated,
        templateDeferredPrefixDuplicatedCause,
        templateDuplicatedDeclaration,
        templateDuplicatedDeclarationCause,
        templateMissingPartOf,
        templateNotAPrefixInTypeAnnotation,
        templatePartOfInLibrary,
        templatePartOfLibraryNameMismatch,
        templatePartOfUriMismatch,
        templatePartOfUseUri,
        templatePartTwice;

import '../import.dart' show Import;

import '../configuration.dart' show Configuration;

import '../problems.dart' show unexpected, unhandled;

import 'source_loader.dart' show SourceLoader;

abstract class SourceLibraryBuilder<T extends TypeBuilder, R>
    extends LibraryBuilder<T, R> {
  static const String MALFORMED_URI_SCHEME = "org-dartlang-malformed-uri";

  final SourceLoader loader;

  final DeclarationBuilder<T> libraryDeclaration;

  final List<ConstructorReferenceBuilder> constructorReferences =
      <ConstructorReferenceBuilder>[];

  final List<SourceLibraryBuilder<T, R>> parts = <SourceLibraryBuilder<T, R>>[];

  // Can I use library.parts instead? See KernelLibraryBuilder.addPart.
  final List<int> partOffsets = <int>[];

  final List<Import> imports = <Import>[];

  final List<Export> exports = <Export>[];

  final Scope importScope;

  final Uri fileUri;

  final List<List> implementationBuilders = <List<List>>[];

  final List<Object> accessors = <Object>[];

  final bool legacyMode;

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

  /// Non-null if this library causes an error upon access, that is, there was
  /// an error reading its source.
  Message accessProblem;

  SourceLibraryBuilder(SourceLoader loader, Uri fileUri, Scope scope)
      : this.fromScopes(loader, fileUri, new DeclarationBuilder<T>.library(),
            scope ?? new Scope.top());

  SourceLibraryBuilder.fromScopes(
      this.loader, this.fileUri, this.libraryDeclaration, this.importScope)
      : currentDeclaration = libraryDeclaration,
        legacyMode = loader.target.legacyMode,
        super(
            fileUri, libraryDeclaration.toScope(importScope), new Scope.top());

  Uri get uri;

  @override
  bool get isPart => partOfName != null || partOfUri != null;

  List<UnresolvedType<T>> get types => libraryDeclaration.types;

  @override
  bool get isSynthetic => accessProblem != null;

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
            currentDeclaration.name == "operator" ||
            identical(name, "<syntax-error>"),
        "${name} != ${currentDeclaration.name}");
    DeclarationBuilder<T> previous = currentDeclaration;
    currentDeclaration = currentDeclaration.parent;
    return previous;
  }

  bool uriIsValid(Uri uri) => uri.scheme != MALFORMED_URI_SCHEME;

  Uri resolve(Uri baseUri, String uri, int uriOffset, {isPart: false}) {
    if (uri == null) {
      addProblem(messageExpectedUri, uriOffset, noLength, this.uri);
      return new Uri(scheme: MALFORMED_URI_SCHEME);
    }
    Uri parsedUri;
    try {
      parsedUri = Uri.parse(uri);
    } on FormatException catch (e) {
      // Point to position in string indicated by the exception,
      // or to the initial quote if no position is given.
      // (Assumes the directive is using a single-line string.)
      addProblem(templateCouldNotParseUri.withArguments(uri, e.message),
          uriOffset + 1 + (e.offset ?? -1), 1, this.uri);
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
      prefix = name.qualifier;
      suffix = name.name;
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
      builder = loader.read(resolvedUri, uriOffset, accessor: this);
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
    partOffsets.add(charOffset);
  }

  void addPartOf(
      List<MetadataBuilder> metadata, String name, String uri, int uriOffset) {
    partOfName = name;
    if (uri != null) {
      partOfUri = resolve(this.uri, uri, uriOffset);
      Uri newFileUri = resolve(fileUri, uri, uriOffset);
      LibraryBuilder library = loader.read(partOfUri, uriOffset,
          fileUri: newFileUri, accessor: this);
      if (loader.first == this) {
        // This is a part, and it was the first input. Let the loader know
        // about that.
        loader.first = library;
      }
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
      int supertypeOffset);

  void addNamedMixinApplication(
      String documentationComment,
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      int modifiers,
      T mixinApplication,
      List<T> interfaces,
      int startCharOffset,
      int charOffset,
      int charEndOffset);

  void addField(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      T type,
      String name,
      int charOffset,
      int charEndOffset,
      Token initializerTokenForInference,
      bool hasInitializer);

  void addFields(String documentationComment, List<MetadataBuilder> metadata,
      int modifiers, T type, List<FieldInfo> fieldInfos) {
    for (FieldInfo info in fieldInfos) {
      String name = info.name;
      int charOffset = info.charOffset;
      int charEndOffset = info.charEndOffset;
      bool hasInitializer = info.initializerTokenForInference != null;
      Token initializerTokenForInference =
          type != null || legacyMode ? null : info.initializerTokenForInference;
      if (initializerTokenForInference != null) {
        Token beforeLast = info.beforeLast;
        beforeLast.setNext(new Token.eof(beforeLast.next.offset));
      }
      addField(
          documentationComment,
          metadata,
          modifiers,
          type,
          name,
          charOffset,
          charEndOffset,
          initializerTokenForInference,
          hasInitializer);
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
      {bool isTopLevel});

  void addEnum(
      String documentationComment,
      List<MetadataBuilder> metadata,
      String name,
      List<EnumConstantInfo> enumConstantInfos,
      int startCharOffset,
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
    if (name == null) {
      unhandled("null", "name", charOffset, fileUri);
    }
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
    if (!isConstructor && name == currentDeclaration.name) {
      addProblem(
          messageMemberWithSameNameAsClass, charOffset, noLength, fileUri);
    }
    Map<String, Declaration> members = isConstructor
        ? currentDeclaration.constructors
        : (declaration.isSetter
            ? currentDeclaration.setters
            : currentDeclaration.members);
    Declaration existing = members[name];
    if (declaration.next != null && declaration.next != existing) {
      unexpected(
          "${declaration.next.fileUri}@${declaration.next.charOffset}",
          "${existing?.fileUri}@${existing?.charOffset}",
          declaration.charOffset,
          declaration.fileUri);
    }
    declaration.next = existing;
    if (declaration is PrefixBuilder && existing is PrefixBuilder) {
      assert(existing.next is! PrefixBuilder);
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
        addProblem(templateDeferredPrefixDuplicated.withArguments(name),
            deferred.charOffset, noLength, fileUri,
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
    } else if (isDuplicatedDeclaration(existing, declaration)) {
      String fullName = name;
      if (isConstructor) {
        if (name.isEmpty) {
          fullName = currentDeclaration.name;
        } else {
          fullName = "${currentDeclaration.name}.$name";
        }
      }
      addProblem(templateDuplicatedDeclaration.withArguments(fullName),
          charOffset, fullName.length, declaration.fileUri,
          context: <LocatedMessage>[
            templateDuplicatedDeclarationCause
                .withArguments(fullName)
                .withLocation(
                    existing.fileUri, existing.charOffset, fullName.length)
          ]);
    }
    return members[name] = declaration;
  }

  bool isDuplicatedDeclaration(Declaration existing, Declaration other) {
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
    Iterator<Declaration> iterator = this.iterator;
    while (iterator.moveNext()) {
      buildBuilder(iterator.current, coreLibrary);
    }
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
      addProblem(templateConflictsWithMember.withArguments(name),
          setter.charOffset, noLength, fileUri);
      // TODO(ahe): Context to previous message?
      addProblem(templateConflictsWithSetter.withArguments(name),
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

  void validatePart(SourceLibraryBuilder library, Set<Uri> usedParts) {
    if (library != null && parts.isNotEmpty) {
      // If [library] is null, we have already reported a problem that this
      // part is orphaned.
      List<LocatedMessage> context = <LocatedMessage>[
        messagePartInPartLibraryContext.withLocation(library.fileUri, -1, 1),
      ];
      for (int offset in partOffsets) {
        addProblem(messagePartInPart, offset, noLength, fileUri,
            context: context);
      }
      for (SourceLibraryBuilder part in parts) {
        // Mark this part as used so we don't report it as orphaned.
        usedParts.add(part.uri);
      }
    }
    parts.clear();
    if (exporters.isNotEmpty) {
      List<LocatedMessage> context = <LocatedMessage>[
        messagePartExportContext.withLocation(fileUri, -1, 1),
      ];
      for (Export export in exporters) {
        export.exporter.addProblem(
            messagePartExport, export.charOffset, "export".length, null,
            context: context);
      }
    }
  }

  void includeParts(Set<Uri> usedParts) {
    Set<Uri> seenParts = new Set<Uri>();
    for (int i = 0; i < parts.length; i++) {
      SourceLibraryBuilder<T, R> part = parts[i];
      int partOffset = partOffsets[i];
      if (part == this) {
        addProblem(messagePartOfSelf, -1, noLength, fileUri);
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
          if (isPatch) {
            usedParts.add(part.fileUri);
          } else {
            usedParts.add(part.uri);
          }
          includePart(part, usedParts, partOffset);
        }
      } else {
        addProblem(templatePartTwice.withArguments(part.fileUri), -1, noLength,
            fileUri);
      }
    }
  }

  void includePart(
      SourceLibraryBuilder<T, R> part, Set<Uri> usedParts, int partOffset) {
    if (part.partOfUri != null) {
      if (uriIsValid(part.partOfUri) && part.partOfUri != uri) {
        // This is an error, but the part is not removed from the list of parts,
        // so that metadata annotations can be associated with it.
        addProblem(
            templatePartOfUriMismatch.withArguments(
                part.fileUri, uri, part.partOfUri),
            partOffset,
            noLength,
            fileUri);
        return;
      }
    } else if (part.partOfName != null) {
      if (name != null) {
        if (part.partOfName != name) {
          // This is an error, but the part is not removed from the list of
          // parts, so that metadata annotations can be associated with it.
          addProblem(
              templatePartOfLibraryNameMismatch.withArguments(
                  part.fileUri, name, part.partOfName),
              partOffset,
              noLength,
              fileUri);
          return;
        }
      } else {
        // This is an error, but the part is not removed from the list of parts,
        // so that metadata annotations can be associated with it.
        addProblem(
            templatePartOfUseUri.withArguments(
                part.fileUri, fileUri, part.partOfName),
            partOffset,
            noLength,
            fileUri);
        return;
      }
    } else {
      // This is an error, but the part is not removed from the list of parts,
      // so that metadata annotations can be associated with it.
      assert(!part.isPart);
      if (uriIsValid(part.fileUri)) {
        addProblem(templateMissingPartOf.withArguments(part.fileUri),
            partOffset, noLength, fileUri);
      }
      return;
    }
    part.validatePart(this, usedParts);
    NameIterator partDeclarations = part.nameIterator;
    while (partDeclarations.moveNext()) {
      String name = partDeclarations.name;
      Declaration declaration = partDeclarations.current;

      if (declaration.next != null) {
        List<Declaration> duplicated = <Declaration>[];
        while (declaration.next != null) {
          duplicated.add(declaration);
          partDeclarations.moveNext();
          declaration = partDeclarations.current;
        }
        duplicated.add(declaration);
        // Handle duplicated declarations in the part.
        //
        // Duplicated declarations are handled by creating a linked list using
        // the `next` field. This is preferred over making all scope entries be
        // a `List<Declaration>`.
        //
        // We maintain the linked list so that the last entry is easy to
        // recognize (it's `next` field is null). This means that it is
        // reversed with respect to source code order. Since kernel doesn't
        // allow duplicated declarations, we ensure that we only add the first
        // declaration to the kernel tree.
        //
        // Since the duplicated declarations are stored in reverse order, we
        // iterate over them in reverse order as this is simpler and normally
        // not a problem. However, in this case we need to call [addBuilder] in
        // source order as it would otherwise create cycles.
        //
        // We also need to be careful preserving the order of the links. The
        // part library still keeps these declarations in its scope so that
        // DietListener can find them.
        for (int i = duplicated.length; i > 0; i--) {
          Declaration declaration = duplicated[i - 1];
          addBuilder(name, declaration, declaration.charOffset);
        }
      } else {
        addBuilder(name, declaration, declaration.charOffset);
      }
    }
    types.addAll(part.types);
    constructorReferences.addAll(part.constructorReferences);
    part.partOfLibrary = this;
    part.scope.becomePartOf(scope);
    // TODO(ahe): Include metadata from part?
  }

  void buildInitialScopes() {
    NameIterator iterator = nameIterator;
    while (iterator.moveNext()) {
      addToExportScope(iterator.name, iterator.current);
    }
  }

  void addImportsToScope() {
    bool explicitCoreImport = this == loader.coreLibrary;
    for (Import import in imports) {
      if (import.imported == loader.coreLibrary) {
        explicitCoreImport = true;
      }
      if (import.imported?.isPart ?? false) {
        addProblem(
            templatePartOfInLibrary.withArguments(import.imported.fileUri),
            import.charOffset,
            noLength,
            fileUri);
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
      if (!loader.target.legacyMode) {
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
    Iterator<Declaration> iterator = this.iterator;
    while (iterator.moveNext()) {
      count += iterator.current.resolveConstructors(this);
    }
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
  void recordAccess(int charOffset, int length, Uri fileUri) {
    accessors.add(fileUri);
    accessors.add(charOffset);
    accessors.add(length);
    if (accessProblem != null) {
      addProblem(accessProblem, charOffset, length, fileUri);
    }
  }

  void addProblemAtAccessors(Message message) {
    if (accessProblem == null) {
      if (accessors.isEmpty && this == loader.first) {
        // This is the entry point library, and nobody access it directly. So
        // we need to report a problem.
        loader.addProblem(message, -1, 1, null);
      }
      for (int i = 0; i < accessors.length; i += 3) {
        Uri accessor = accessors[i];
        int charOffset = accessors[i + 1];
        int length = accessors[i + 2];
        addProblem(message, charOffset, length, accessor);
      }
      accessProblem = message;
    }
  }

  void checkBoundsInOutline(covariant typeEnvironment);

  int finalizeInitializingFormals();
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

  bool hasConstConstructor = false;

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
    Map<String, TypeVariableBuilder> map;
    if (typeVariables != null) {
      map = <String, TypeVariableBuilder>{};
      for (TypeVariableBuilder builder in typeVariables) {
        map[builder.name] = builder;
      }
    }
    Scope scope;
    for (UnresolvedType<T> type in types) {
      Object nameOrQualified = type.builder.name;
      String name = nameOrQualified is QualifiedName
          ? nameOrQualified.qualifier
          : nameOrQualified;
      Declaration declaration;
      if (name != null) {
        if (members != null) {
          declaration = members[name];
        }
        if (declaration == null && map != null) {
          declaration = map[name];
        }
      }
      if (declaration == null) {
        // Since name didn't resolve in this scope, propagate it to the
        // parent declaration.
        parent.addType(type);
      } else if (nameOrQualified is QualifiedName) {
        // Attempt to use a member or type variable as a prefix.
        type.builder.bind(type.builder.buildInvalidType(
            templateNotAPrefixInTypeAnnotation
                .withArguments(
                    flattenName(nameOrQualified.qualifier, type.charOffset,
                        type.fileUri),
                    nameOrQualified.name)
                .withLocation(type.fileUri, type.charOffset,
                    nameOrQualified.endCharOffset - type.charOffset)));
      } else {
        scope ??= toScope(null).withTypeVariables(typeVariables);
        type.resolveIn(scope, library);
      }
    }
    types.clear();
  }

  Scope toScope(Scope parent) {
    return new Scope(members, setters, parent, name, isModifiable: false);
  }
}

class FieldInfo {
  final String name;
  final int charOffset;
  final Token initializerTokenForInference;
  final Token beforeLast;
  final int charEndOffset;

  const FieldInfo(this.name, this.charOffset, this.initializerTokenForInference,
      this.beforeLast, this.charEndOffset);
}
