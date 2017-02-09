// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_library_builder;

import 'package:kernel/ast.dart' show
    AsyncMarker,
    ProcedureKind;

import '../combinator.dart' show
    Combinator;

import '../errors.dart' show
    inputError,
    internalError;

import '../import.dart' show
    Import;

import 'source_loader.dart' show
    SourceLoader;

import '../builder/scope.dart' show
    Scope;

import '../builder/builder.dart' show
    Builder,
    ClassBuilder,
    ConstructorReferenceBuilder,
    EnumBuilder,
    FieldBuilder,
    FormalParameterBuilder,
    FunctionTypeAliasBuilder,
    LibraryBuilder,
    MemberBuilder,
    MetadataBuilder,
    NamedMixinApplicationBuilder,
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

  final List<LibraryBuilder> parts = <LibraryBuilder>[];

  final List<Import> imports = <Import>[];

  final Map<String, Builder> exports = <String, Builder>{};

  final Scope scope = new Scope(<String, Builder>{}, null, isModifiable: false);

  final Uri fileUri;

  String name;

  String partOf;

  List<MetadataBuilder> metadata;

  /// The current declaration that is being built. When we start parsing a
  /// declaration (class, method, and so on), we don't have enough information
  /// to create a builder and this object records its members and types until,
  /// for example, [addClass] is called.
  DeclarationBuilder<T> currentDeclaration;

  SourceLibraryBuilder(this.loader, this.fileUri) {
    currentDeclaration = libraryDeclaration;
  }

  Uri get uri;

  bool get isPart => partOf != null;

  Map<String, Builder> get members => libraryDeclaration.members;

  List<T> get types => libraryDeclaration.types;

  /// When parsing a class, this returns a map of its members (that have been
  /// parsed so far).
  Map<String, MemberBuilder> get classMembers {
    assert(currentDeclaration.parent == libraryDeclaration);
    return currentDeclaration.members;
  }

  List<T> get declarationTypes {
    assert(currentDeclaration.parent == libraryDeclaration);
    return currentDeclaration.types;
  }

  T addNamedType(String name, List<T> arguments);

  T addMixinApplication(T supertype, List<T> mixins);

  T addType(T type) {
    currentDeclaration.addType(type);
    return type;
  }

  T addVoidType();

  ConstructorReferenceBuilder addConstructorReference(
      String name, List<T> typeArguments, String suffix) {
    ConstructorReferenceBuilder ref =
        new ConstructorReferenceBuilder(name, typeArguments, suffix);
    constructorReferences.add(ref);
    return ref;
  }

  void beginNestedDeclaration({bool hasMembers}) {
    currentDeclaration =
        new DeclarationBuilder(<String, MemberBuilder>{}, currentDeclaration);
  }

  DeclarationBuilder<T> endNestedDeclaration() {
    DeclarationBuilder<T> previous = currentDeclaration;
    currentDeclaration = currentDeclaration.parent;
    return previous;
  }

  Uri resolve(String path) => uri.resolve(path);

  void addExport(List<MetadataBuilder> metadata, String uri,
      Unhandled conditionalUris, List<Combinator> combinators) {
    loader.read(resolve(uri)).addExporter(this, combinators);
  }

  void addImport(List<MetadataBuilder> metadata, String uri,
      Unhandled conditionalUris, String prefix, List<Combinator> combinators,
      bool deferred) {
    imports.add(new Import(loader.read(resolve(uri)), prefix, combinators));
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

  void addPartOf(List<MetadataBuilder> metadata, String name) {
    partOf = name;
  }

  ClassBuilder addClass(List<MetadataBuilder> metadata,
      int modifiers, String name,
      List<TypeVariableBuilder> typeVariables, T supertype,
      List<T> interfaces);

  NamedMixinApplicationBuilder addNamedMixinApplication(
      List<MetadataBuilder> metadata, String name,
      List<TypeVariableBuilder> typeVariables, int modifiers,
      T mixinApplication, List<T> interfaces);

  FieldBuilder addField(List<MetadataBuilder> metadata,
      int modifiers, T type, String name);

  void addFields(List<MetadataBuilder> metadata, int modifiers,
      T type, List<String> names) {
    for (String name in names) {
      addField(metadata, modifiers, type, name);
    }
  }

  ProcedureBuilder addProcedure(List<MetadataBuilder> metadata,
      int modifiers, T returnType, String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals, AsyncMarker asyncModifier,
      ProcedureKind kind);

  EnumBuilder addEnum(List<MetadataBuilder> metadata, String name,
      List<String> constants);

  FunctionTypeAliasBuilder addFunctionTypeAlias(List<MetadataBuilder> metadata,
      T returnType, String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals);

  void addFactoryMethod(List<MetadataBuilder> metadata,
      ConstructorReferenceBuilder name, List<FormalParameterBuilder> formals,
      AsyncMarker asyncModifier, ConstructorReferenceBuilder redirectionTarget);

  FormalParameterBuilder addFormalParameter(
      List<MetadataBuilder> metadata, int modifiers,
      T type, String name, bool hasThis);

  TypeVariableBuilder addTypeVariable(String name, T bound);

  Builder addBuilder(String name, Builder builder) {
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
              other.combineAmbiguousImport(name, builder, this);
        }
      });
      return existing;
    } else if (existing != null && (existing.next != null ||
            ((!existing.isGetter || !builder.isSetter) &&
                (!existing.isSetter || !builder.isGetter)))) {
      return inputError(uri, -1, "Duplicated definition of $name");
    }
    return members[name] = builder;
  }

  void buildBuilder(Builder builder);

  R build() {
    members.forEach((String name, Builder builder) {
      do {
        buildBuilder(builder);
        builder = builder.next;
      } while (builder != null);
    });
    return null;
  }

  void validatePart() {
    if (parts.isNotEmpty) {
      internalError("Part with parts: $uri");
    }
    if (exporters.isNotEmpty) {
      internalError(
          "${exporters.first.exporter.uri} attempts to export the part $uri.");
    }
  }

  void includeParts() {
    for (LibraryBuilder part in parts.toList()) {
      includePart(part);
    }
  }

  void includePart(SourceLibraryBuilder part) {
    if (name != null) {
      if (part.partOf == null) {
        print("${part.uri} has no 'part of' declaration but is used as a part "
            "by ${name} ($uri)");
        parts.remove(part);
        return;
      }
      if (part.partOf != name) {
        print("${part.uri} is part of '${part.partOf}' but is used as a part "
            "by '${name}' ($uri)");
        parts.remove(part);
        return;
      }
    }
    part.members.forEach(addBuilder);
    types.addAll(part.types);
    constructorReferences.addAll(part.constructorReferences);
    part.partOfLibrary = this;
    // TODO(ahe): Include metadata from part?
  }

  void buildInitialScopes() {
    members.forEach(addToExportScope);
    members.forEach(addToScope);
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
      loader.coreLibrary.exports.forEach(addToScope);
    }
  }

  void addToScope(String name, Builder member) {
    Builder existing = scope.lookup(name);
    if (existing != null) {
      if (existing != member) {
        scope.local[name] = existing.combineAmbiguousImport(name, member, this);
      }
      // TODO(ahe): handle duplicated names.
    } else {
      scope.local[name] = member;
    }
  }

  bool addToExportScope(String name, Builder member) {
    if (name.startsWith("_")) return false;
    if (member is PrefixBuilder) return false;
    Builder existing = exports[name];
    if (existing != null) {
      // TODO(ahe): handle duplicated names.
      return false;
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

  int convertConstructors(_) {
    int count = 0;
    members.forEach((String name, Builder member) {
      count += member.convertConstructors(this);
    });
    return count;
  }

  int resolveConstructors(_) {
    int count = 0;
    members.forEach((String name, Builder member) {
      count += member.resolveConstructors(this);
    });
    return count;
  }
}

/// Unlike [Scope], this scope is used during construction of builders to
/// ensure types and members are added to and resolved in the correct location.
class DeclarationBuilder<T extends TypeBuilder> {
  final DeclarationBuilder<T> parent;

  final Map<String, Builder> members;

  final List<T> types = <T>[];

  DeclarationBuilder(this.members, [this.parent]);

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
  void resolveTypes(List<TypeVariableBuilder> typeVariables) {
    // TODO(ahe): The input to this method, [typeVariables], shouldn't be just
    // type variables. It should be everything that's in scope, for example,
    // members (of a class) or formal parameters (of a method).
    if (typeVariables == null) {
      // If there are no type variables in the scope, propagate our types to be
      // resolved in the parent declaration.
      parent.types.addAll(types);
    } else {
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
}
