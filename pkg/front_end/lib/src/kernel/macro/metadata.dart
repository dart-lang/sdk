// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/metadata/expressions.dart' as shared;
import 'package:_fe_analyzer_shared/src/metadata/parser.dart' as shared;
import 'package:_fe_analyzer_shared/src/metadata/proto.dart' as shared;
import 'package:_fe_analyzer_shared/src/metadata/references.dart' as shared;
import 'package:_fe_analyzer_shared/src/metadata/scope.dart' as shared;
import 'package:_fe_analyzer_shared/src/metadata/type_annotations.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:kernel/ast.dart';

import '../../base/loader.dart';
import '../../base/scope.dart';
import '../../builder/builder.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/dynamic_type_declaration_builder.dart';
import '../../builder/field_builder.dart';
import '../../builder/future_or_type_declaration_builder.dart';
import '../../builder/member_builder.dart';
import '../../builder/never_type_declaration_builder.dart';
import '../../builder/null_type_declaration_builder.dart';
import '../../builder/prefix_builder.dart';
import '../../builder/procedure_builder.dart';

// Coverage-ignore(suite): Not run.
final Uri dummyUri = Uri.parse('dummy:uri');

// Coverage-ignore(suite): Not run.
bool _isDartLibrary(Uri importUri, Uri fileUri) {
  return importUri.isScheme("dart") || fileUri.isScheme("org-dartlang-sdk");
}

// Coverage-ignore(suite): Not run.
/// Creates a [shared.Expression] for the annotation at [atToken].
///
/// If [delayLookupForTesting] is `true`, identifiers are not looked up in their
/// corresponding scopes. This means that the return expression will contain
/// [shared.UnresolvedIdentifier] nodes, as if the identifier wasn't in scope.
/// A subsequent call to [shared.Expression.resolve] will perform the lookup
/// a create the resolved expression. This is used in testing to mimic the
/// scenario in which the declaration is added to the scope via macros.
shared.Expression parseAnnotation(
    Loader loader, Token atToken, Uri importUri, Uri fileUri, LookupScope scope,
    {bool delayLookupForTesting = false}) {
  return shared.parseAnnotation(
      atToken, fileUri, new AnnotationScope(scope), new References(loader),
      isDartLibrary: _isDartLibrary(importUri, fileUri),
      delayLookupForTesting: delayLookupForTesting);
}

// Coverage-ignore(suite): Not run.
shared.Proto builderToProto(Builder builder, String name) {
  if (builder is FieldBuilder) {
    return new shared.FieldProto(new FieldReference(builder));
  } else if (builder is ProcedureBuilder) {
    return new shared.FunctionProto(new FunctionReference(builder));
  } else if (builder is PrefixBuilder) {
    return new shared.PrefixProto(name, new PrefixScope(builder));
  } else if (builder is ClassBuilder) {
    if (builder.isEnum) {
      shared.EnumReference enumReference = new EnumReference(builder);
      return new shared.EnumProto(
          enumReference, new EnumScope(builder, enumReference));
    } else if (builder.isMixinDeclaration) {
      shared.MixinReference mixinReference = new MixinReference(builder);
      return new shared.MixinProto(
          mixinReference, new MixinScope(builder, mixinReference));
    } else {
      shared.ClassReference classReference = new ClassReference(builder);
      return new shared.ClassProto(
          classReference, new ClassScope(builder, classReference));
    }
  } else if (builder is DynamicTypeDeclarationBuilder) {
    return new shared.DynamicProto(new TypeReference(builder));
  } else if (builder is TypeAliasBuilder) {
    shared.TypedefReference typedefReference = new TypedefReference(builder);
    return new shared.TypedefProto(
        typedefReference, new TypedefScope(builder, typedefReference));
  } else if (builder is ExtensionBuilder) {
    shared.ExtensionReference extensionReference =
        new ExtensionReference(builder);
    return new shared.ExtensionProto(
        extensionReference, new ExtensionScope(builder, extensionReference));
  } else if (builder is ExtensionTypeDeclarationBuilder) {
    shared.ExtensionTypeReference extensionReference =
        new ExtensionTypeReference(builder);
    return new shared.ExtensionTypeProto(extensionReference,
        new ExtensionTypeScope(builder, extensionReference));
  } else {
    // TODO(johnniwinther): Support extension types.
    throw new UnsupportedError("Unsupported builder $builder for $name");
  }
}

// Coverage-ignore(suite): Not run.
class References implements shared.References {
  final Loader loader;

  late final DynamicTypeDeclarationBuilder dynamicDeclaration =
      new DynamicTypeDeclarationBuilder(
          const DynamicType(), loader.coreLibrary, -1);

  late final NeverTypeDeclarationBuilder neverDeclaration =
      new NeverTypeDeclarationBuilder(
          const NeverType.nonNullable(), loader.coreLibrary, -1);

  late final NullTypeDeclarationBuilder nullDeclaration =
      new NullTypeDeclarationBuilder(const NullType(), loader.coreLibrary, -1);

  late final FutureOrTypeDeclarationBuilder futureOrDeclaration =
      new FutureOrTypeDeclarationBuilder(
          new FutureOrType(const DynamicType(), Nullability.nonNullable),
          loader.coreLibrary,
          -1);

  @override
  late final shared.TypeReference dynamicReference =
      new TypeReference(dynamicDeclaration);

  @override
  shared.TypeReference get voidReference => const VoidTypeReference();

  References(this.loader);
}

// Coverage-ignore(suite): Not run.
class AnnotationScope implements shared.Scope {
  final LookupScope scope;

  AnnotationScope(this.scope);

  @override
  shared.Proto lookup(String name) {
    int fileOffset = -1;
    Uri fileUri = dummyUri;
    Builder? builder = scope.lookupGetable(name, fileOffset, fileUri);
    if (builder == null) {
      return new shared.UnresolvedIdentifier(this, name);
    } else {
      return builderToProto(builder, name);
    }
  }
}

// Coverage-ignore(suite): Not run.
final class ClassScope extends shared.BaseClassScope {
  final ClassBuilder builder;
  @override
  final shared.ClassReference classReference;

  ClassScope(this.builder, this.classReference);

  @override
  shared.Proto lookup(String name,
      [List<shared.TypeAnnotation>? typeArguments]) {
    int fileOffset = -1;
    Uri fileUri = dummyUri;
    MemberBuilder? constructor =
        builder.constructorScope.lookup(name, fileOffset, fileUri);
    if (constructor != null) {
      return createConstructorProto(
          typeArguments, new ConstructorReference(constructor));
    }
    Builder? member = builder.lookupLocalMember(name, setter: false);
    return createMemberProto(typeArguments, name, member, builderToProto);
  }
}

// Coverage-ignore(suite): Not run.
final class EnumScope extends shared.BaseEnumScope {
  final ClassBuilder builder;
  @override
  final shared.EnumReference enumReference;

  EnumScope(this.builder, this.enumReference);

  @override
  shared.Proto lookup(String name,
      [List<shared.TypeAnnotation>? typeArguments]) {
    Builder? member = builder.lookupLocalMember(name, setter: false);
    return createMemberProto(typeArguments, name, member, builderToProto);
  }
}

// Coverage-ignore(suite): Not run.
final class MixinScope extends shared.BaseMixinScope {
  final ClassBuilder builder;
  @override
  final shared.MixinReference mixinReference;

  MixinScope(this.builder, this.mixinReference);

  @override
  shared.Proto lookup(String name,
      [List<shared.TypeAnnotation>? typeArguments]) {
    Builder? member = builder.lookupLocalMember(name, setter: false);
    return createMemberProto(typeArguments, name, member, builderToProto);
  }
}

// Coverage-ignore(suite): Not run.
final class ExtensionScope extends shared.BaseExtensionScope {
  final ExtensionBuilder builder;
  @override
  final shared.ExtensionReference extensionReference;

  ExtensionScope(this.builder, this.extensionReference);

  @override
  shared.Proto lookup(String name,
      [List<shared.TypeAnnotation>? typeArguments]) {
    Builder? member = builder.lookupLocalMember(name, setter: false);
    return createMemberProto(typeArguments, name, member, builderToProto);
  }
}

// Coverage-ignore(suite): Not run.
final class ExtensionTypeScope extends shared.BaseExtensionTypeScope {
  final ExtensionTypeDeclarationBuilder builder;
  @override
  final shared.ExtensionTypeReference extensionTypeReference;

  ExtensionTypeScope(this.builder, this.extensionTypeReference);

  @override
  shared.Proto lookup(String name,
      [List<shared.TypeAnnotation>? typeArguments]) {
    int fileOffset = -1;
    Uri fileUri = dummyUri;
    MemberBuilder? constructor =
        builder.constructorScope.lookup(name, fileOffset, fileUri);
    if (constructor != null) {
      return createConstructorProto(
          typeArguments, new ConstructorReference(constructor));
    }
    Builder? member = builder.lookupLocalMember(name, setter: false);
    return createMemberProto(typeArguments, name, member, builderToProto);
  }
}

// Coverage-ignore(suite): Not run.
final class TypedefScope extends shared.BaseTypedefScope {
  final TypeAliasBuilder builder;

  @override
  final shared.TypedefReference typedefReference;

  TypedefScope(this.builder, this.typedefReference);

  @override
  shared.Proto lookup(String name,
      [List<shared.TypeAnnotation>? typeArguments]) {
    int fileOffset = -1;
    Uri fileUri = dummyUri;
    TypeDeclarationBuilder? typeDeclaration = builder.unaliasDeclaration(null);
    if (typeDeclaration is ClassBuilder) {
      MemberBuilder? constructor =
          typeDeclaration.constructorScope.lookup(name, fileOffset, fileUri);
      if (constructor != null) {
        return createConstructorProto(
            typeArguments, new ConstructorReference(constructor));
      }
    }
    return createMemberProto(typeArguments, name);
  }
}

// Coverage-ignore(suite): Not run.
class TypeReference extends shared.TypeReference {
  final TypeDeclarationBuilder builder;

  TypeReference(this.builder);

  @override
  String get name => builder.name;
}

class VoidTypeReference extends shared.TypeReference {
  const VoidTypeReference();

  @override
  // Coverage-ignore(suite): Not run.
  String get name => 'void';
}

// Coverage-ignore(suite): Not run.
class PrefixScope implements shared.Scope {
  final PrefixBuilder prefixBuilder;

  PrefixScope(this.prefixBuilder);

  @override
  shared.Proto lookup(String name) {
    int fileOffset = -1;
    Uri fileUri = dummyUri;
    Builder? builder = prefixBuilder.lookup(name, fileOffset, fileUri);
    if (builder == null) {
      return new shared.UnresolvedIdentifier(this, name);
    } else {
      return builderToProto(builder, name);
    }
  }
}

// Coverage-ignore(suite): Not run.
class FieldReference extends shared.FieldReference {
  final FieldBuilder builder;

  FieldReference(this.builder);

  @override
  String get name => builder.name;
}

// Coverage-ignore(suite): Not run.
class FunctionReference extends shared.FunctionReference {
  final ProcedureBuilder builder;

  FunctionReference(this.builder);

  @override
  String get name => builder.name;
}

// Coverage-ignore(suite): Not run.
class ConstructorReference extends shared.ConstructorReference {
  final MemberBuilder builder;

  ConstructorReference(this.builder);

  @override
  String get name => builder.name.isEmpty ? 'new' : builder.name;
}

// Coverage-ignore(suite): Not run.
class ClassReference extends shared.ClassReference {
  final ClassBuilder builder;

  ClassReference(this.builder);

  @override
  String get name => builder.name;
}

// Coverage-ignore(suite): Not run.
class EnumReference extends shared.EnumReference {
  final ClassBuilder builder;

  EnumReference(this.builder);

  @override
  String get name => builder.name;
}

// Coverage-ignore(suite): Not run.
class MixinReference extends shared.MixinReference {
  final ClassBuilder builder;

  MixinReference(this.builder);

  @override
  String get name => builder.name;
}

// Coverage-ignore(suite): Not run.
class ExtensionReference extends shared.ExtensionReference {
  final ExtensionBuilder builder;

  ExtensionReference(this.builder);

  @override
  String get name => builder.name;
}

// Coverage-ignore(suite): Not run.
class ExtensionTypeReference extends shared.ExtensionTypeReference {
  final ExtensionTypeDeclarationBuilder builder;

  ExtensionTypeReference(this.builder);

  @override
  String get name => builder.name;
}

// Coverage-ignore(suite): Not run.
class TypedefReference extends shared.TypedefReference {
  final TypeAliasBuilder builder;

  TypedefReference(this.builder);

  @override
  String get name => builder.name;
}
