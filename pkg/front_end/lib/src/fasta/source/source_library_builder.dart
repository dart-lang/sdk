// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_library_builder;

import 'package:kernel/ast.dart' show AsyncMarker, ProcedureKind;

import '../combinator.dart' show Combinator;

import '../errors.dart' show inputError, internalError;

import '../export.dart' show Export;

import '../import.dart' show Import;

import 'source_loader.dart' show SourceLoader;

import '../builder/scope.dart' show Scope;

import '../builder/builder.dart'
    show
        Builder,
        ClassBuilder,
        ConstructorReferenceBuilder,
        FormalParameterBuilder,
        FunctionTypeBuilder,
        LibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        PrefixBuilder,
        ProcedureBuilder,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder,
        Unhandled;

abstract class SourceLibraryBuilder<T extends TypeBuilder, R>
    extends LibraryBuilder<T, R> {
  final SourceLoader loader;

  final DeclarationBuilder<T> libraryDeclaration =
      new DeclarationBuilder<T>(<String, Builder>{}, null);

  final List<ConstructorReferenceBuilder> constructorReferences =
      <ConstructorReferenceBuilder>[];

  final List<SourceLibraryBuilder<T, R>> parts = <SourceLibraryBuilder<T, R>>[];

  final List<Import> imports = <Import>[];

  final Map<String, Builder> exports = <String, Builder>{};

  final Scope scope = new Scope(<String, Builder>{}, null, isModifiable: false);

  final Uri fileUri;

  final List<List> implementationBuilders = <List<List>>[];

  String name;

  String partOfName;

  Uri partOfUri;

  List<MetadataBuilder> metadata;

  /// The current declaration that is being built. When we start parsing a
  /// declaration (class, method, and so on), we don't have enough information
  /// to create a builder and this object records its members and types until,
  /// for example, [addClass] is called.
  DeclarationBuilder<T> currentDeclaration;

  SourceLibraryBuilder(this.loader, Uri fileUri)
      : fileUri = fileUri,
        super(fileUri) {
    currentDeclaration = libraryDeclaration;
  }

  Uri get uri;

  bool get isPart => partOfName != null || partOfUri != null;

  Map<String, Builder> get members => libraryDeclaration.members;

  List<T> get types => libraryDeclaration.types;

  /// When parsing a class, this returns a map of its members (that have been
  /// parsed so far).
  Map<String, MemberBuilder> get classMembers {
    assert(currentDeclaration.parent == libraryDeclaration);
    return currentDeclaration.members;
  }

  T addNamedType(String name, List<T> arguments, int charOffset);

  T addMixinApplication(T supertype, List<T> mixins, int charOffset);

  T addType(T type) {
    currentDeclaration.addType(type);
    return type;
  }

  T addVoidType(int charOffset);

  ConstructorReferenceBuilder addConstructorReference(
      String name, List<T> typeArguments, String suffix, int charOffset) {
    ConstructorReferenceBuilder ref = new ConstructorReferenceBuilder(
        name, typeArguments, suffix, this, charOffset);
    constructorReferences.add(ref);
    return ref;
  }

  void beginNestedDeclaration(String name, {bool hasMembers}) {
    currentDeclaration = new DeclarationBuilder(
        <String, MemberBuilder>{}, name, currentDeclaration);
  }

  DeclarationBuilder<T> endNestedDeclaration() {
    DeclarationBuilder<T> previous = currentDeclaration;
    currentDeclaration = currentDeclaration.parent;
    return previous;
  }

  Uri resolve(String path) => uri.resolve(path);

  void addExport(List<MetadataBuilder> metadata, String uri,
      Unhandled conditionalUris, List<Combinator> combinators, int charOffset) {
    loader.read(resolve(uri)).addExporter(this, combinators, charOffset);
  }

  void addImport(
      List<MetadataBuilder> metadata,
      String uri,
      Unhandled conditionalUris,
      String prefix,
      List<Combinator> combinators,
      bool deferred,
      int charOffset,
      int prefixCharOffset) {
    imports.add(new Import(this, loader.read(resolve(uri)), prefix, combinators,
        charOffset, prefixCharOffset));
  }

  void addPart(List<MetadataBuilder> metadata, String path) {
    Uri resolvedUri;
    Uri newFileUri;
    if (uri.scheme == "dart") {
      resolvedUri = new Uri(scheme: "dart", path: "${uri.path}/$path");
      newFileUri = fileUri.resolve(path);
    } else {
      resolvedUri = uri.resolve(path);
      newFileUri = fileUri.resolve(path);
    }
    parts.add(loader.read(resolvedUri, newFileUri));
  }

  void addPartOf(List<MetadataBuilder> metadata, String name, String uri) {
    partOfName = name;
    partOfUri = uri == null ? null : this.uri.resolve(uri);
  }

  void addClass(
      List<MetadataBuilder> metadata,
      int modifiers,
      String name,
      List<TypeVariableBuilder> typeVariables,
      T supertype,
      List<T> interfaces,
      int charOffset);

  void addNamedMixinApplication(
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      int modifiers,
      T mixinApplication,
      List<T> interfaces,
      int charOffset);

  void addField(List<MetadataBuilder> metadata, int modifiers, T type,
      String name, int charOffset);

  void addFields(List<MetadataBuilder> metadata, int modifiers, T type,
      List<Object> namesAndOffsets) {
    for (int i = 0; i < namesAndOffsets.length; i += 2) {
      String name = namesAndOffsets[i];
      int charOffset = namesAndOffsets[i + 1];
      addField(metadata, modifiers, type, name, charOffset);
    }
  }

  void addProcedure(
      List<MetadataBuilder> metadata,
      int modifiers,
      T returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      AsyncMarker asyncModifier,
      ProcedureKind kind,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName,
      {bool isTopLevel});

  void addEnum(List<MetadataBuilder> metadata, String name,
      List<Object> constantNamesAndOffsets, int charOffset, int charEndOffset);

  void addFunctionTypeAlias(
      List<MetadataBuilder> metadata,
      T returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      int charOffset);

  FunctionTypeBuilder addFunctionType(
      T returnType,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      int charOffset);

  void addFactoryMethod(
      List<MetadataBuilder> metadata,
      int modifiers,
      ConstructorReferenceBuilder name,
      List<FormalParameterBuilder> formals,
      AsyncMarker asyncModifier,
      ConstructorReferenceBuilder redirectionTarget,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      String nativeMethodName);

  FormalParameterBuilder addFormalParameter(List<MetadataBuilder> metadata,
      int modifiers, T type, String name, bool hasThis, int charOffset);

  TypeVariableBuilder addTypeVariable(String name, T bound, int charOffset);

  Builder addBuilder(String name, Builder builder, int charOffset) {
    if (name.indexOf(".") != -1 && name.indexOf("&") == -1) {
      addCompileTimeError(
          charOffset,
          "Only constructors and factories can have"
          " names containing a period ('.'): $name");
    }
    // TODO(ahe): Set the parent correctly here. Could then change the
    // implementation of MemberBuilder.isTopLevel to test explicitly for a
    // LibraryBuilder.
    if (currentDeclaration == libraryDeclaration) {
      if (builder is MemberBuilder) {
        builder.parent = this;
      } else if (builder is TypeDeclarationBuilder) {
        builder.parent = this;
      } else if (builder is PrefixBuilder) {
        assert(builder.parent == this);
      } else {
        return internalError("Unhandled: ${builder.runtimeType}");
      }
    } else {
      assert(currentDeclaration.parent == libraryDeclaration);
    }
    Map<String, Builder> members = currentDeclaration.members;
    Builder existing = members[name];
    builder.next = existing;
    if (builder is PrefixBuilder && existing is PrefixBuilder) {
      assert(existing.next == null);
      builder.exports.forEach((String name, Builder builder) {
        Builder other = existing.exports.putIfAbsent(name, () => builder);
        if (other != builder) {
          existing.exports[name] =
              buildAmbiguousBuilder(name, other, builder, charOffset);
        }
      });
      return existing;
    } else if (isDuplicatedDefinition(existing, builder)) {
      addCompileTimeError(charOffset, "Duplicated definition of '$name'.");
    }
    return members[name] = builder;
  }

  bool isDuplicatedDefinition(Builder existing, Builder other) {
    if (existing == null) return false;
    Builder next = existing.next;
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

  void buildBuilder(Builder builder);

  R build() {
    assert(implementationBuilders.isEmpty);
    members.forEach((String name, Builder builder) {
      do {
        buildBuilder(builder);
        builder = builder.next;
      } while (builder != null);
    });
    for (List list in implementationBuilders) {
      String name = list[0];
      Builder builder = list[1];
      int charOffset = list[2];
      addBuilder(name, builder, charOffset);
      buildBuilder(builder);
    }
    return null;
  }

  void addImplementationBuilder(String name, Builder builder, int charOffset) {
    implementationBuilders.add([name, builder, charOffset]);
  }

  void validatePart() {
    if (parts.isNotEmpty) {
      inputError(fileUri, -1,
          "A file that's a part of a library can't have parts itself.");
    }
    if (exporters.isNotEmpty) {
      Export export = exporters.first;
      inputError(
          export.fileUri, export.charOffset, "A part can't be exported.");
    }
  }

  void includeParts() {
    Set<Uri> seenParts = new Set<Uri>();
    for (SourceLibraryBuilder<T, R> part in parts.toList()) {
      if (part == this) {
        addCompileTimeError(-1, "A file can't be a part of itself.");
      } else if (seenParts.add(part.fileUri)) {
        includePart(part);
      } else {
        addCompileTimeError(
            -1, "Can't use '${part.fileUri}' as a part more than once.");
      }
    }
  }

  void includePart(SourceLibraryBuilder<T, R> part) {
    if (name != null) {
      if (!part.isPart) {
        addCompileTimeError(
            -1,
            "Can't use ${part.fileUri} as a part, because it has no 'part of'"
            " declaration.");
        parts.remove(part);
        return;
      }
      if (part.partOfName != name && part.partOfUri != uri) {
        String partName = part.partOfName ?? "${part.partOfUri}";
        String myName = name == null ? "'$uri'" : "'${name}' ($uri)";
        addWarning(
            -1,
            "Using '${part.fileUri}' as part of '$myName' but it's 'part of'"
            " declaration says '$partName'.");
        // The part is still included.
      }
    }
    part.members.forEach((String name, Builder builder) {
      if (builder.next != null) {
        assert(builder.next.next == null);
        addBuilder(name, builder.next, builder.next.charOffset);
      }
      addBuilder(name, builder, builder.charOffset);
    });
    types.addAll(part.types);
    constructorReferences.addAll(part.constructorReferences);
    part.partOfLibrary = this;
    // TODO(ahe): Include metadata from part?
  }

  void buildInitialScopes() {
    members.forEach(addToExportScope);
    members.forEach((String name, Builder member) {
      addToScope(name, member, member.charOffset, false);
    });
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
      loader.coreLibrary.exports.forEach((String name, Builder member) {
        addToScope(name, member, -1, true);
      });
    }
  }

  @override
  void addToScope(String name, Builder member, int charOffset, bool isImport) {
    Builder existing = scope.lookup(name, member.charOffset, fileUri);
    if (existing != null) {
      if (existing != member) {
        scope.local[name] = buildAmbiguousBuilder(
            name, existing, member, charOffset,
            isImport: isImport);
      }
    } else {
      scope.local[name] = member;
    }
  }

  /// Returns true if the export scope was modified.
  bool addToExportScope(String name, Builder member) {
    if (name.startsWith("_")) return false;
    if (member is PrefixBuilder) return false;
    Builder existing = exports[name];
    if (existing == member) return false;
    if (existing != null) {
      Builder result =
          buildAmbiguousBuilder(name, existing, member, -1, isExport: true);
      exports[name] = result;
      return result != existing;
    } else {
      exports[name] = member;
    }
    return true;
  }

  int resolveTypes(_) {
    int typeCount = types.length;
    for (T t in types) {
      t.resolveIn(scope);
    }
    members.forEach((String name, Builder member) {
      typeCount += member.resolveTypes(this);
    });
    return typeCount;
  }

  int resolveConstructors(_) {
    int count = 0;
    members.forEach((String name, Builder member) {
      count += member.resolveConstructors(this);
    });
    return count;
  }

  List<TypeVariableBuilder> copyTypeVariables(
      List<TypeVariableBuilder> original);

  @override
  String get fullNameForErrors => name ?? "<library '$relativeFileUri'>";
}

/// Unlike [Scope], this scope is used during construction of builders to
/// ensure types and members are added to and resolved in the correct location.
class DeclarationBuilder<T extends TypeBuilder> {
  final DeclarationBuilder<T> parent;

  final Map<String, Builder> members;

  final List<T> types = <T>[];

  final String name;

  final Map<ProcedureBuilder, DeclarationBuilder<T>> factoryDeclarations =
      <ProcedureBuilder, DeclarationBuilder<T>>{};

  DeclarationBuilder(this.members, this.name, [this.parent]);

  void addMember(String name, MemberBuilder builder) {
    if (members == null) {
      parent.addMember(name, builder);
    } else {
      members[name] = builder;
    }
  }

  MemberBuilder lookupMember(String name) {
    return members == null ? parent.lookupMember(name) : members[name];
  }

  void addType(T type) {
    types.add(type);
  }

  /// Resolves type variables in [types] and propagate other types to [parent].
  void resolveTypes(
      List<TypeVariableBuilder> typeVariables, SourceLibraryBuilder library) {
    // TODO(ahe): The input to this method, [typeVariables], shouldn't be just
    // type variables. It should be everything that's in scope, for example,
    // members (of a class) or formal parameters (of a method).
    if (typeVariables == null) {
      // If there are no type variables in the scope, propagate our types to be
      // resolved in the parent declaration.
      factoryDeclarations.forEach((_, DeclarationBuilder<T> declaration) {
        parent.types.addAll(declaration.types);
      });
      parent.types.addAll(types);
    } else {
      factoryDeclarations.forEach(
          (ProcedureBuilder procedure, DeclarationBuilder<T> declaration) {
        assert(procedure.typeVariables.isEmpty);
        procedure.typeVariables
            .addAll(library.copyTypeVariables(typeVariables));
        declaration.resolveTypes(procedure.typeVariables, library);
      });
      Map<String, TypeVariableBuilder> map = <String, TypeVariableBuilder>{};
      for (TypeVariableBuilder builder in typeVariables) {
        map[builder.name] = builder;
      }
      for (T type in types) {
        String name = type.name;
        TypeVariableBuilder builder;
        if (name != null) {
          builder = map[name];
        }
        if (builder == null) {
          // Since name didn't resolve in this scope, propagate it to the
          // parent declaration.
          parent.addType(type);
        } else {
          type.bind(builder);
        }
      }
    }
    types.clear();
  }

  /// Called to register [procedure] as a factory whose types are collected in
  /// [factoryDeclaration]. Later, once the class has been built, we can
  /// synthesize type variables on the factory matching the class'.
  void addFactoryDeclaration(
      ProcedureBuilder procedure, DeclarationBuilder<T> factoryDeclaration) {
    factoryDeclarations[procedure] = factoryDeclaration;
  }
}
