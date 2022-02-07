// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.named_type_builder;

import 'package:kernel/ast.dart';

import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        Severity,
        Template,
        messageNotATypeContext,
        messageTypeVariableInStaticContext,
        messageTypedefCause,
        noLength,
        templateExperimentNotEnabled,
        templateExtendingRestricted,
        templateNotAType,
        templateSupertypeIsIllegal,
        templateSupertypeIsIllegalAliased,
        templateSupertypeIsNullableAliased,
        templateSupertypeIsTypeVariable,
        templateTypeArgumentMismatch,
        templateTypeArgumentsOnTypeVariable,
        templateTypeNotFound;

import '../identifiers.dart' show Identifier, QualifiedName, flattenName;

import '../problems.dart' show unhandled;

import '../scope.dart';

import '../source/source_library_builder.dart';

import 'builder.dart';
import 'builtin_type_declaration_builder.dart';
import 'class_builder.dart';
import 'invalid_type_declaration_builder.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'prefix_builder.dart';
import 'type_alias_builder.dart';
import 'type_builder.dart';
import 'type_declaration_builder.dart';
import 'type_variable_builder.dart';
import 'void_type_declaration_builder.dart';

/// Enum used to determine how instance type variable access is allowed.
enum InstanceTypeVariableAccessState {
  /// Instance type variable access is allowed.
  ///
  /// This is used for valid references to instance type variables, like
  ///
  ///     class Class<T> {
  ///       void instanceMethod(T t) {}
  ///     }
  Allowed,

  /// Instance type variable access is disallowed and results in a compile-time
  /// error.
  ///
  /// This is used for static references to instance type variables, like
  ///
  ///     class Class<T> {
  ///       static void staticMethod(T t) {}
  ///     }
  ///
  /// The type is resolved as an [InvalidType].
  Disallowed,

  /// Instance type variable access is invalid since it occurs in an invalid
  /// context. The occurrence _doesn't_ result in a compile-time error.
  ///
  /// This is used for references to instance type variables where they might
  /// be valid if the context where, like
  ///
  ///     class Extension<T> {
  ///       T field; // Instance extension fields are not allowed.
  ///     }
  ///
  /// The type is resolved as an [InvalidType].
  Invalid,

  /// Instance type variable access is unexpected and results in an assertion
  /// failure.
  ///
  /// This is used for [NamedTypeBuilder]s for known non-type variable types,
  /// like for `Object` and `String`.
  Unexpected,
}

class NamedTypeBuilder extends TypeBuilder {
  @override
  final Object name;

  List<TypeBuilder>? arguments;

  @override
  final NullabilityBuilder nullabilityBuilder;

  @override
  final Uri? fileUri;

  @override
  final int? charOffset;

  @override
  TypeDeclarationBuilder? declaration;

  final InstanceTypeVariableAccessState instanceTypeVariableAccess;

  NamedTypeBuilder(this.name, this.nullabilityBuilder, this.arguments,
      this.fileUri, this.charOffset,
      {required this.instanceTypeVariableAccess})
      : assert(name is String || name is QualifiedName);

  NamedTypeBuilder.fromTypeDeclarationBuilder(
      TypeDeclarationBuilder this.declaration, this.nullabilityBuilder,
      {this.arguments,
      this.fileUri,
      this.charOffset,
      required this.instanceTypeVariableAccess})
      : this.name = declaration.name;

  @override
  bool get isVoidType => declaration is VoidTypeDeclarationBuilder;

  @override
  void bind(TypeDeclarationBuilder declaration) {
    this.declaration = declaration.origin;
  }

  int get nameOffset {
    if (name is Identifier) {
      Identifier identifier = name as Identifier;
      return identifier.charOffset;
    }
    return -1; // TODO(eernst): make it possible to get offset.
  }

  int get nameLength {
    if (name is Identifier) {
      Identifier identifier = name as Identifier;
      return identifier.name.length;
    } else if (name is String) {
      String nameString = name as String;
      return nameString.length;
    } else {
      return noLength;
    }
  }

  @override
  void resolveIn(
      Scope scope, int charOffset, Uri fileUri, LibraryBuilder library) {
    if (declaration != null) return;
    final Object name = this.name;
    Builder? member;
    if (name is QualifiedName) {
      Object qualifier = name.qualifier;
      String prefixName = flattenName(qualifier, charOffset, fileUri);
      Builder? prefix = scope.lookup(prefixName, charOffset, fileUri);
      if (prefix is PrefixBuilder) {
        member = prefix.lookup(name.name, name.charOffset, fileUri);
      }
    } else if (name is String) {
      member = scope.lookup(name, charOffset, fileUri);
    } else {
      unhandled("${name.runtimeType}", "resolveIn", charOffset, fileUri);
    }
    if (member is TypeVariableBuilder) {
      declaration = member.origin;
      if (arguments != null) {
        String typeName;
        int typeNameOffset;
        if (name is Identifier) {
          typeName = name.name;
          typeNameOffset = name.charOffset;
        } else {
          typeName = name as String;
          typeNameOffset = charOffset;
        }
        Message message =
            templateTypeArgumentsOnTypeVariable.withArguments(typeName);
        library.addProblem(message, typeNameOffset, typeName.length, fileUri);
        declaration = buildInvalidTypeDeclarationBuilder(
            message.withLocation(fileUri, typeNameOffset, typeName.length));
      }
      return;
    } else if (member is TypeDeclarationBuilder) {
      declaration = member.origin;
      if (!declaration!.isExtension ||
          library is SourceLibraryBuilder &&
              library.enableExtensionTypesInLibrary) {
        return;
      }
    }
    Template<Message Function(String name)> template =
        member == null ? templateTypeNotFound : templateNotAType;
    String flatName = flattenName(name, charOffset, fileUri);
    int length =
        name is Identifier ? name.endCharOffset - charOffset : flatName.length;
    Message message;
    List<LocatedMessage>? context;
    if (member == null) {
      template = templateTypeNotFound;
      message = template.withArguments(flatName);
    } else if (declaration != null &&
        declaration!.isExtension &&
        library is SourceLibraryBuilder &&
        !library.enableExtensionTypesInLibrary) {
      message = templateExperimentNotEnabled.withArguments('extension-types',
          library.enableExtensionTypesVersionInLibrary.toText());
    } else {
      template = templateNotAType;
      context = <LocatedMessage>[
        messageNotATypeContext.withLocation(member.fileUri!, member.charOffset,
            name is Identifier ? name.name.length : "$name".length)
      ];
      message = template.withArguments(flatName);
    }
    library.addProblem(message, charOffset, length, fileUri, context: context);
    declaration = buildInvalidTypeDeclarationBuilder(
        message.withLocation(fileUri, charOffset, length),
        context: context);
  }

  @override
  void check(LibraryBuilder library, int charOffset, Uri fileUri) {
    if (arguments != null &&
        arguments!.length != declaration!.typeVariablesCount) {
      Message message = templateTypeArgumentMismatch
          .withArguments(declaration!.typeVariablesCount);
      library.addProblem(message, charOffset, noLength, fileUri);
      declaration = buildInvalidTypeDeclarationBuilder(
          message.withLocation(fileUri, charOffset, noLength));
    }
  }

  @override
  String get debugName => "NamedTypeBuilder";

  @override
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(flattenName(name, charOffset ?? TreeNode.noOffset, fileUri));
    if (arguments?.isEmpty ?? true) return buffer;
    buffer.write("<");
    bool first = true;
    for (TypeBuilder t in arguments!) {
      if (!first) buffer.write(", ");
      first = false;
      t.printOn(buffer);
    }
    buffer.write(">");
    nullabilityBuilder.writeNullabilityOn(buffer);
    return buffer;
  }

  InvalidTypeDeclarationBuilder buildInvalidTypeDeclarationBuilder(
      LocatedMessage message,
      {List<LocatedMessage>? context}) {
    // TODO(ahe): Consider if it makes sense to pass a QualifiedName to
    // InvalidTypeBuilder?
    return new InvalidTypeDeclarationBuilder(
        flattenName(name, message.charOffset, message.uri), message,
        context: context);
  }

  Supertype? handleInvalidSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    Template<Message Function(String name)> template =
        declaration!.isTypeVariable
            ? templateSupertypeIsTypeVariable
            : templateSupertypeIsIllegal;
    library.addProblem(template.withArguments(fullNameForErrors), charOffset,
        noLength, fileUri);
    return null;
  }

  Supertype? handleInvalidAliasedSupertype(
      LibraryBuilder library,
      int charOffset,
      Uri fileUri,
      TypeAliasBuilder aliasBuilder,
      DartType type) {
    // Don't report the error in case of InvalidType. An error has already been
    // reported in this case.
    if (type is InvalidType) return null;

    Message message;
    if (declaration!.isTypeVariable) {
      message =
          templateSupertypeIsTypeVariable.withArguments(fullNameForErrors);
    } else
    // ignore: unnecessary_null_comparison
    if (type != null && type.nullability == Nullability.nullable) {
      message = templateSupertypeIsNullableAliased.withArguments(
          fullNameForErrors, type, library.isNonNullableByDefault);
    } else {
      message = templateSupertypeIsIllegalAliased.withArguments(
          fullNameForErrors, type, library.isNonNullableByDefault);
    }
    library.addProblem(message, charOffset, noLength, fileUri, context: [
      messageTypedefCause.withLocation(
          aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
    ]);
    return null;
  }

  @override
  DartType build(LibraryBuilder library, {TypedefType? origin}) {
    return buildInternal(library, origin: origin, forTypeLiteral: false);
  }

  @override
  DartType buildTypeLiteralType(LibraryBuilder library, {TypedefType? origin}) {
    return buildInternal(library, origin: origin, forTypeLiteral: true);
  }

  DartType declarationBuildType(LibraryBuilder library,
      {required bool forTypeLiteral}) {
    if (forTypeLiteral) {
      return declaration!
          .buildTypeLiteralType(library, nullabilityBuilder, arguments);
    } else {
      return declaration!.buildType(library, nullabilityBuilder, arguments);
    }
  }

  // TODO(johnniwinther): Store [origin] on the built type.
  DartType buildInternal(LibraryBuilder library,
      {TypedefType? origin, required bool forTypeLiteral}) {
    assert(declaration != null, "Declaration has not been resolved on $this.");
    if (declaration!.isTypeVariable) {
      TypeVariableBuilder typeParameterBuilder =
          declaration as TypeVariableBuilder;
      TypeParameter typeParameter = typeParameterBuilder.parameter;
      if (typeParameter.parent is Class || typeParameter.parent is Extension) {
        switch (instanceTypeVariableAccess) {
          case InstanceTypeVariableAccessState.Disallowed:
            library.addProblem(
                messageTypeVariableInStaticContext,
                charOffset ?? TreeNode.noOffset,
                noLength,
                fileUri ?? library.fileUri);
            return const InvalidType();
          case InstanceTypeVariableAccessState.Invalid:
            return const InvalidType();
          case InstanceTypeVariableAccessState.Unexpected:
            assert(false,
                "Unexpected instance type variable $typeParameterBuilder");
            break;
          case InstanceTypeVariableAccessState.Allowed:
            break;
        }
      }
    }

    if (library is SourceLibraryBuilder) {
      int uncheckedTypedefTypeCount = library.uncheckedTypedefTypes.length;
      DartType builtType =
          declarationBuildType(library, forTypeLiteral: forTypeLiteral);
      // Set locations for new unchecked TypedefTypes for error reporting.
      for (int i = uncheckedTypedefTypeCount;
          i < library.uncheckedTypedefTypes.length;
          ++i) {
        // TODO(johnniwinther): Pass the uri/offset through the build methods
        // to avoid this.
        library.uncheckedTypedefTypes[i]
          ..fileUri ??= fileUri
          ..offset ??= charOffset;
      }
      return builtType;
    } else {
      return declarationBuildType(library, forTypeLiteral: forTypeLiteral);
    }
  }

  @override
  Supertype? buildSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    TypeDeclarationBuilder declaration = this.declaration!;
    if (declaration is ClassBuilder) {
      if (declaration.isNullClass && !library.mayImplementRestrictedTypes) {
        library.addProblem(
            templateExtendingRestricted.withArguments(declaration.name),
            charOffset,
            noLength,
            fileUri);
      }
      return declaration.buildSupertype(library, arguments);
    } else if (declaration is TypeAliasBuilder) {
      TypeAliasBuilder aliasBuilder = declaration;
      DartType type = build(library);
      if (type is InterfaceType && type.nullability != Nullability.nullable) {
        return new Supertype(type.classNode, type.typeArguments);
      } else if (type is NullType) {
        // Even though Null is disallowed as a supertype, ClassHierarchyBuilder
        // still expects it to be built to the respective InterfaceType
        // referencing the deprecated class.
        // TODO(dmitryas): Remove the dependency on the deprecated Null class
        // from ClassHierarchyBuilder.
        TypeDeclarationBuilder? unaliasedDeclaration = this.declaration;
        // The following code assumes that the declaration is a TypeAliasBuilder
        // that through a chain of other TypeAliasBuilders (possibly, the chain
        // length is 0) references a ClassBuilder of the Null class.  Otherwise,
        // it won't produce the NullType on the output.
        while (unaliasedDeclaration is TypeAliasBuilder) {
          unaliasedDeclaration = unaliasedDeclaration.type?.declaration;
          assert(unaliasedDeclaration != null);
        }
        assert(unaliasedDeclaration is ClassBuilder &&
            unaliasedDeclaration.name == "Null");
        return new Supertype(
            (unaliasedDeclaration as ClassBuilder).cls, const <DartType>[]);
      } else if (type is FutureOrType) {
        // Even though FutureOr is disallowed as a supertype,
        // ClassHierarchyBuilder still expects it to be built to the respective
        // InterfaceType referencing the deprecated class.  In contrast with
        // Null, it doesn't surface as an error due to FutureOr class not having
        // any inheritable members.
        // TODO(dmitryas): Remove the dependency on the deprecated FutureOr
        // class from ClassHierarchyBuilder.
        TypeDeclarationBuilder? unaliasedDeclaration = this.declaration;
        // The following code assumes that the declaration is a TypeAliasBuilder
        // that through a chain of other TypeAliasBuilders (possibly, the chain
        // length is 0) references a ClassBuilder of the FutureOr class.
        // Otherwise, it won't produce the FutureOrType on the output.
        while (unaliasedDeclaration is TypeAliasBuilder) {
          unaliasedDeclaration = unaliasedDeclaration.type?.declaration;
          assert(unaliasedDeclaration != null);
        }
        assert(unaliasedDeclaration is ClassBuilder &&
            unaliasedDeclaration.name == "FutureOr");
        return new Supertype((unaliasedDeclaration as ClassBuilder).cls,
            <DartType>[type.typeArgument]);
      }
      return handleInvalidAliasedSupertype(
          library, charOffset, fileUri, aliasBuilder, type);
    } else if (declaration is InvalidTypeDeclarationBuilder) {
      library.addProblem(
          declaration.message.messageObject,
          declaration.message.charOffset,
          declaration.message.length,
          declaration.message.uri,
          severity: Severity.error);
      return null;
    }
    return handleInvalidSupertype(library, charOffset, fileUri);
  }

  @override
  Supertype? buildMixedInType(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    TypeDeclarationBuilder declaration = this.declaration!;
    if (declaration is ClassBuilder) {
      return declaration.buildMixedInType(library, arguments);
    } else if (declaration is TypeAliasBuilder) {
      TypeAliasBuilder aliasBuilder = declaration;
      DartType type = build(library);
      if (type is InterfaceType && type.nullability != Nullability.nullable) {
        return new Supertype(type.classNode, type.typeArguments);
      }
      return handleInvalidAliasedSupertype(
          library, charOffset, fileUri, aliasBuilder, type);
    } else if (declaration is InvalidTypeDeclarationBuilder) {
      library.addProblem(
          declaration.message.messageObject,
          declaration.message.charOffset,
          declaration.message.length,
          declaration.message.uri,
          severity: Severity.error);
      return null;
    }
    return handleInvalidSupertype(library, charOffset, fileUri);
  }

  @override
  TypeBuilder subst(Map<TypeVariableBuilder, TypeBuilder> substitution) {
    TypeBuilder? result = substitution[declaration];
    if (result != null) {
      assert(declaration is TypeVariableBuilder);
      return result;
    } else if (this.arguments != null) {
      List<TypeBuilder>? arguments;
      int i = 0;
      for (TypeBuilder argument in this.arguments!) {
        TypeBuilder type = argument.subst(substitution);
        if (type != argument) {
          arguments ??= this.arguments!.toList();
          arguments[i] = type;
        }
        i++;
      }
      if (arguments != null) {
        NamedTypeBuilder result = new NamedTypeBuilder(
            name, nullabilityBuilder, arguments, fileUri, charOffset,
            instanceTypeVariableAccess: instanceTypeVariableAccess);
        if (declaration != null) {
          result.bind(declaration!);
        } else {
          throw new UnsupportedError("Unbound type in substitution: $result.");
        }
        return result;
      }
    }
    return this;
  }

  @override
  NamedTypeBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    List<TypeBuilder>? clonedArguments;
    if (arguments != null) {
      clonedArguments =
          new List<TypeBuilder>.generate(arguments!.length, (int i) {
        return arguments![i]
            .clone(newTypes, contextLibrary, contextDeclaration);
      }, growable: false);
    }
    NamedTypeBuilder newType = new NamedTypeBuilder(
        name, nullabilityBuilder, clonedArguments, fileUri, charOffset,
        instanceTypeVariableAccess: instanceTypeVariableAccess);
    if (declaration is BuiltinTypeDeclarationBuilder) {
      newType.declaration = declaration;
    } else {
      newTypes.add(newType);
    }
    return newType;
  }

  @override
  NamedTypeBuilder withNullabilityBuilder(
      NullabilityBuilder nullabilityBuilder) {
    return new NamedTypeBuilder(
        name, nullabilityBuilder, arguments, fileUri, charOffset,
        instanceTypeVariableAccess: instanceTypeVariableAccess)
      ..bind(declaration!);
  }
}
