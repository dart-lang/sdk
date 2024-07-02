// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.named_type_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/unaliasing.dart' as unaliasing;

import '../base/messages.dart'
    show
        LocatedMessage,
        Message,
        ProblemReporting,
        Severity,
        Template,
        messageClassImplementsDeferredClass,
        messageExtendsDeferredClass,
        messageExtensionTypeImplementsDeferred,
        messageMixinDeferredMixin,
        messageMixinSuperClassConstraintDeferredClass,
        messageNotATypeContext,
        messageTypeVariableInStaticContext,
        messageTypedefCause,
        noLength,
        templateExtendingRestricted,
        templateNotAType,
        templateSupertypeIsIllegal,
        templateSupertypeIsIllegalAliased,
        templateSupertypeIsNullableAliased,
        templateSupertypeIsTypeVariable,
        templateTypeArgumentMismatch,
        templateTypeArgumentsOnTypeVariable,
        templateTypeNotFound;
import '../base/scope.dart';
import '../base/uris.dart';
import '../kernel/implicit_field_type.dart';
import '../source/source_library_builder.dart';
import '../util/helpers.dart';
import 'builder.dart';
import 'declaration_builders.dart';
import 'inferable_type_builder.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'prefix_builder.dart';
import 'type_builder.dart';
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

abstract class NamedTypeBuilderImpl extends NamedTypeBuilder {
  @override
  final TypeName typeName;

  @override
  List<TypeBuilder>? typeArguments;

  @override
  final NullabilityBuilder nullabilityBuilder;

  @override
  final Uri? fileUri;

  @override
  final int? charOffset;

  TypeDeclarationBuilder? _declaration;

  final InstanceTypeVariableAccessState _instanceTypeVariableAccess;

  final bool hasExplicitTypeArguments;

  /// Set to `true` if the type was resolved through a deferred import prefix.
  bool _isDeferred = false;

  factory NamedTypeBuilderImpl(
      TypeName name, NullabilityBuilder nullabilityBuilder,
      {List<TypeBuilder>? arguments,
      Uri? fileUri,
      int? charOffset,
      required InstanceTypeVariableAccessState instanceTypeVariableAccess}) {
    bool isExplicit = true;
    if (arguments != null) {
      for (TypeBuilder argument in arguments) {
        if (!argument.isExplicit) {
          isExplicit = false;
        }
      }
    }
    return isExplicit
        ? new _ExplicitNamedTypeBuilder(name, nullabilityBuilder,
            arguments: arguments,
            fileUri: fileUri,
            charOffset: charOffset,
            instanceTypeVariableAccess: instanceTypeVariableAccess)
        :
        // Coverage-ignore(suite): Not run.
        new _InferredNamedTypeBuilder(name, nullabilityBuilder,
            arguments: arguments,
            fileUri: fileUri,
            charOffset: charOffset,
            instanceTypeVariableAccess: instanceTypeVariableAccess);
  }

  NamedTypeBuilderImpl._(
      {required this.typeName,
      required this.nullabilityBuilder,
      this.typeArguments,
      this.fileUri,
      this.charOffset,
      required InstanceTypeVariableAccessState instanceTypeVariableAccess,
      TypeDeclarationBuilder? declaration})
      : this._instanceTypeVariableAccess = instanceTypeVariableAccess,
        this.hasExplicitTypeArguments = typeArguments != null,
        this._declaration = declaration;

  factory NamedTypeBuilderImpl.forDartType(
      DartType type,
      TypeDeclarationBuilder _declaration,
      NullabilityBuilder nullabilityBuilder,
      {List<TypeBuilder>? arguments}) = _ExplicitNamedTypeBuilder.forDartType;

  factory NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
      TypeDeclarationBuilder declaration, NullabilityBuilder nullabilityBuilder,
      {List<TypeBuilder>? arguments,
      Uri? fileUri,
      int? charOffset,
      required InstanceTypeVariableAccessState instanceTypeVariableAccess,
      DartType? type}) = _ExplicitNamedTypeBuilder.fromTypeDeclarationBuilder;

  factory NamedTypeBuilderImpl.forInvalidType(String name,
          NullabilityBuilder nullabilityBuilder, LocatedMessage message,
          {List<LocatedMessage>? context}) =
      _ExplicitNamedTypeBuilder.forInvalidType;

  @override
  TypeDeclarationBuilder? get declaration => _declaration;

  @override
  bool get isVoidType => declaration is VoidTypeDeclarationBuilder;

  @override
  void bind(
      ProblemReporting problemReporting, TypeDeclarationBuilder declaration) {
    _declaration = declaration.origin;
    _check(problemReporting);
  }

  @override
  void resolveIn(Scope scope, int charOffset, Uri fileUri,
      ProblemReporting problemReporting) {
    if (_declaration != null) return;
    Builder? member;
    String? qualifier = typeName.qualifier;
    if (qualifier != null) {
      Builder? prefix = scope.lookup(qualifier, charOffset, fileUri);
      if (prefix is PrefixBuilder) {
        _isDeferred = prefix.deferred;
        member = prefix.lookup(typeName.name, typeName.nameOffset, fileUri);
      }
    } else {
      member = scope.lookup(typeName.name, typeName.nameOffset, fileUri);
    }
    if (member is TypeDeclarationBuilder) {
      bind(problemReporting, member);
    } else {
      Template<Message Function(String name)> template =
          member == null ? templateTypeNotFound : templateNotAType;
      String nameText = typeName.fullName;
      int nameOffset = typeName.fullNameOffset;
      int nameLength = typeName.fullNameLength;
      Message message;
      List<LocatedMessage>? context;
      if (member == null) {
        template = templateTypeNotFound;
        message = template.withArguments(nameText);
      } else {
        template = templateNotAType;
        context = <LocatedMessage>[
          messageNotATypeContext.withLocation(
              member.fileUri!, member.charOffset, nameLength)
        ];
        message = template.withArguments(nameText);
      }
      problemReporting.addProblem(message, nameOffset, nameLength, fileUri,
          context: context);
      TypeDeclarationBuilder declaration = buildInvalidTypeDeclarationBuilder(
          message.withLocation(fileUri, nameOffset, nameLength),
          context: context);
      bind(problemReporting, declaration);
    }
  }

  void _check(ProblemReporting problemReporting) {
    if (_declaration is InvalidTypeDeclarationBuilder) {
      return;
    }
    if (typeArguments != null) {
      if (_declaration!.isTypeVariable) {
        String nameText = typeName.name;
        int nameOffset = typeName.nameOffset;
        int nameLength = typeName.nameLength;
        Message message =
            templateTypeArgumentsOnTypeVariable.withArguments(nameText);
        problemReporting.addProblem(message, nameOffset, nameLength, fileUri);
        // TODO(johnniwinther): Should we retain the declaration to support
        //  additional errors?
        _declaration = buildInvalidTypeDeclarationBuilder(
            message.withLocation(fileUri!, nameOffset, nameLength));
      } else if (typeArguments!.length != declaration!.typeVariablesCount) {
        int nameOffset = typeName.nameOffset;
        int nameLength = typeName.nameLength;
        Message message = templateTypeArgumentMismatch
            .withArguments(declaration!.typeVariablesCount);
        problemReporting.addProblem(message, nameOffset, nameLength, fileUri);
        _declaration = buildInvalidTypeDeclarationBuilder(
            message.withLocation(fileUri!, nameOffset, nameLength));
      }
    }
    // TODO(johnniwinther): Remove check for `is SourceLibraryBuilder`.
    if (_declaration!.isExtension && problemReporting is SourceLibraryBuilder) {
      String nameText = typeName.name;
      int nameOffset = typeName.nameOffset;
      int nameLength = typeName.nameLength;
      // TODO(johnniwinther): Create a custom message.
      Message message = templateNotAType.withArguments(nameText);
      problemReporting.addProblem(message, nameOffset, nameLength, fileUri);
      _declaration = buildInvalidTypeDeclarationBuilder(
          message.withLocation(fileUri!, nameOffset, nameLength));
    } else if (_declaration is NominalVariableBuilder) {
      NominalVariableBuilder typeParameterBuilder =
          _declaration as NominalVariableBuilder;
      if (typeParameterBuilder.kind == TypeVariableKind.classMixinOrEnum ||
          typeParameterBuilder.kind ==
              TypeVariableKind.extensionOrExtensionType ||
          typeParameterBuilder.kind == TypeVariableKind.extensionSynthesized) {
        switch (_instanceTypeVariableAccess) {
          case InstanceTypeVariableAccessState.Disallowed:
            int nameOffset = typeName.nameOffset;
            int nameLength = typeName.nameLength;
            Message message = messageTypeVariableInStaticContext;
            problemReporting.addProblem(
                message, nameOffset, nameLength, fileUri);
            _declaration = buildInvalidTypeDeclarationBuilder(
                message.withLocation(fileUri!, nameOffset, nameLength));
            return;
          case InstanceTypeVariableAccessState.Invalid:
            int nameOffset = typeName.nameOffset;
            int nameLength = typeName.nameLength;
            Message message = messageTypeVariableInStaticContext;
            _declaration = buildInvalidTypeDeclarationBuilder(
                message.withLocation(fileUri!, nameOffset, nameLength));
            return;
          case InstanceTypeVariableAccessState.Unexpected:
            // Coverage-ignore(suite): Not run.
            assert(false,
                "Unexpected instance type variable $typeParameterBuilder");
            break;
          case InstanceTypeVariableAccessState.Allowed:
            break;
        }
      }
    }
  }

  @override
  String get debugName => "NamedTypeBuilder";

  @override
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(typeName.fullName);
    List<TypeBuilder>? typeArguments = this.typeArguments;
    if (typeArguments != null && typeArguments.isNotEmpty) {
      buffer.write("<");
      bool first = true;
      for (TypeBuilder t in typeArguments) {
        if (!first) {
          // Coverage-ignore-block(suite): Not run.
          buffer.write(", ");
        }
        first = false;
        t.printOn(buffer);
      }
      buffer.write(">");
    }
    nullabilityBuilder.writeNullabilityOn(buffer);
    return buffer;
  }

  @override
  InvalidTypeDeclarationBuilder buildInvalidTypeDeclarationBuilder(
      LocatedMessage message,
      {List<LocatedMessage>? context}) {
    return new InvalidTypeDeclarationBuilder(typeName.fullName, message,
        context: context);
  }

  Supertype? _handleInvalidSupertype(LibraryBuilder library) {
    Template<Message Function(String name)> template =
        declaration!.isTypeVariable
            ? templateSupertypeIsTypeVariable
            : templateSupertypeIsIllegal;
    library.addProblem(template.withArguments(fullNameForErrors), charOffset!,
        noLength, fileUri);
    return null;
  }

  Supertype? _handleInvalidAliasedSupertype(
      LibraryBuilder library, TypeAliasBuilder aliasBuilder, DartType type) {
    // Don't report the error in case of InvalidType. An error has already been
    // reported in this case.
    if (type is InvalidType) return null;

    Message message;
    if (declaration!.isTypeVariable) {
      // Coverage-ignore-block(suite): Not run.
      message =
          templateSupertypeIsTypeVariable.withArguments(fullNameForErrors);
    } else if (type.nullability == Nullability.nullable) {
      message = templateSupertypeIsNullableAliased.withArguments(
          fullNameForErrors, type);
    } else {
      message = templateSupertypeIsIllegalAliased.withArguments(
          fullNameForErrors, type);
    }
    library.addProblem(message, charOffset!, noLength, fileUri, context: [
      messageTypedefCause.withLocation(
          aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
    ]);
    return null;
  }

  void _checkDeferred(SourceLibraryBuilder libraryBuilder, TypeUse typeUse) {
    if (_isDeferred) {
      switch (typeUse) {
        case TypeUse.classExtendsType:
          libraryBuilder.addProblem(
              messageExtendsDeferredClass,
              typeName.fullNameOffset,
              typeName.fullNameLength,
              fileUri ?? // Coverage-ignore(suite): Not run.
                  libraryBuilder.fileUri);
        case TypeUse.classImplementsType:
          libraryBuilder.addProblem(
              messageClassImplementsDeferredClass,
              typeName.fullNameOffset,
              typeName.fullNameLength,
              fileUri ?? // Coverage-ignore(suite): Not run.
                  libraryBuilder.fileUri);
        case TypeUse.mixinOnType:
          libraryBuilder.addProblem(
              messageMixinSuperClassConstraintDeferredClass,
              typeName.fullNameOffset,
              typeName.fullNameLength,
              fileUri ?? // Coverage-ignore(suite): Not run.
                  libraryBuilder.fileUri);
        case TypeUse.extensionTypeImplementsType:
          libraryBuilder.addProblem(
              messageExtensionTypeImplementsDeferred,
              typeName.fullNameOffset,
              typeName.fullNameLength,
              fileUri ?? // Coverage-ignore(suite): Not run.
                  libraryBuilder.fileUri);
        case TypeUse.classWithType:
          libraryBuilder.addProblem(
              messageMixinDeferredMixin,
              typeName.fullNameOffset,
              typeName.fullNameLength,
              fileUri ?? // Coverage-ignore(suite): Not run.
                  libraryBuilder.fileUri);
        case TypeUse.literalTypeArgument:
        case TypeUse.variableType:
        case TypeUse.typeParameterBound:
        case TypeUse.parameterType:
        case TypeUse.recordEntryType:
        case TypeUse.fieldType:
        case TypeUse.returnType:
        case TypeUse.isType:
        case TypeUse.asType:
        case TypeUse.objectPatternType:
        case TypeUse.catchType:
        case TypeUse.constructorTypeArgument:
        case TypeUse.redirectionTypeArgument:
        case TypeUse.tearOffTypeArgument:
        case TypeUse.invocationTypeArgument:
        case TypeUse.typeLiteral:
        case TypeUse.extensionOnType:
        case TypeUse.extensionTypeRepresentationType:
        // Coverage-ignore(suite): Not run.
        case TypeUse.typeArgument:
        // Coverage-ignore(suite): Not run.
        case TypeUse.typedefAlias:
        // Coverage-ignore(suite): Not run.
        case TypeUse.instantiation:
        // Coverage-ignore(suite): Not run.
        case TypeUse.enumSelfType:
        // Coverage-ignore(suite): Not run.
        case TypeUse.macroTypeArgument:
        // Coverage-ignore(suite): Not run.
        case TypeUse.typeParameterDefaultType:
        // Coverage-ignore(suite): Not run.
        case TypeUse.defaultTypeAsTypeArgument:
        // Coverage-ignore(suite): Not run.
        case TypeUse.deferredTypeError:
      }
    }
  }

  DartType _buildInternal(LibraryBuilder libraryBuilder, TypeUse typeUse,
      ClassHierarchyBase? hierarchy) {
    DartType aliasedType =
        _buildAliasedInternal(libraryBuilder, typeUse, hierarchy);
    if (libraryBuilder is SourceLibraryBuilder) {
      _checkDeferred(libraryBuilder, typeUse);
      if (!isRecordAccessAllowed(libraryBuilder) &&
          // Coverage-ignore(suite): Not run.
          isDartCoreRecord(aliasedType)) {
        // Coverage-ignore-block(suite): Not run.
        libraryBuilder.reportFeatureNotEnabled(
            libraryBuilder.libraryFeatures.records,
            fileUri ?? libraryBuilder.fileUri,
            typeName.fullNameOffset,
            typeName.fullNameLength);
      }
    }
    return unaliasing.unalias(aliasedType, legacyEraseAliases: false);
  }

  @override
  TypeBuilder? unalias(
      {Set<TypeAliasBuilder>? usedTypeAliasBuilders,
      List<TypeBuilder>? unboundTypes,
      List<StructuralVariableBuilder>? unboundTypeVariables}) {
    assert(
        declaration != null, // Coverage-ignore(suite): Not run.
        "Declaration has not been resolved on $this.");
    if (declaration is TypeAliasBuilder) {
      return (declaration as TypeAliasBuilder).unalias(typeArguments,
          usedTypeAliasBuilders: usedTypeAliasBuilders,
          unboundTypes: unboundTypes,
          unboundTypeVariables: unboundTypeVariables);
    }
    return this;
  }

  @override
  DartType buildAliased(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    assert(
        hierarchy != null || isExplicit, // Coverage-ignore(suite): Not run.
        "Cannot build $this.");
    DartType builtType = _buildAliasedInternal(library, typeUse, hierarchy);
    if (library is SourceLibraryBuilder &&
        !isRecordAccessAllowed(library) &&
        // Coverage-ignore(suite): Not run.
        isDartCoreRecord(builtType)) {
      // Coverage-ignore-block(suite): Not run.
      library.reportFeatureNotEnabled(
          library.libraryFeatures.records,
          fileUri ?? library.fileUri,
          typeName.fullNameOffset,
          typeName.fullNameLength);
    }

    return builtType;
  }

  DartType _buildAliasedInternal(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    assert(
        declaration != null, // Coverage-ignore(suite): Not run.
        "Declaration has not been resolved on $this.");
    return declaration!.buildAliasedType(
        library,
        nullabilityBuilder,
        typeArguments,
        typeUse,
        fileUri ?? missingUri,
        charOffset ?? TreeNode.noOffset,
        hierarchy,
        hasExplicitTypeArguments: hasExplicitTypeArguments);
  }

  @override
  Supertype? buildSupertype(LibraryBuilder library, TypeUse typeUse) {
    TypeDeclarationBuilder declaration = this.declaration!;
    switch (declaration) {
      case ClassBuilder():
        if (declaration.isNullClass) {
          // Coverage-ignore-block(suite): Not run.
          if (!library.mayImplementRestrictedTypes) {
            library.addProblem(
                templateExtendingRestricted.withArguments(declaration.name),
                charOffset!,
                noLength,
                fileUri);
          }
        }
        DartType type = build(library, typeUse);
        if (type is InterfaceType) {
          return new Supertype(type.classNode, type.typeArguments);
        }
        // Coverage-ignore(suite): Not run.
        else if (type is FutureOrType) {
          return new Supertype(declaration.cls, [type.typeArgument]);
        } else if (type is NullType) {
          return new Supertype(declaration.cls, []);
        }
      case TypeAliasBuilder():
        TypeAliasBuilder aliasBuilder = declaration;
        DartType type = build(library, typeUse);
        if (type is InterfaceType && type.nullability != Nullability.nullable) {
          return new Supertype(type.classNode, type.typeArguments);
        } else if (type is NullType) {
          // Coverage-ignore-block(suite): Not run.
          // Even though `Null` is disallowed as a supertype,
          // [ClassHierarchyBuilder] still expects it to be built to the
          // respective [InterfaceType] referencing the deprecated class.
          // TODO(cstefantsova): Remove the dependency on the deprecated Null
          // class from ClassHierarchyBuilder.
          TypeDeclarationBuilder? unaliasedDeclaration = this.declaration;
          // The following code assumes that the declaration is a
          // [TypeAliasBuilder] that through a chain of other
          // [TypeAliasBuilder]s (possibly, the chain length is 0) references a
          // [ClassBuilder] of the `Null` class. Otherwise, it won't produce the
          // [NullType] on the output.
          while (unaliasedDeclaration is TypeAliasBuilder) {
            unaliasedDeclaration = unaliasedDeclaration.type.declaration;
            assert(unaliasedDeclaration != null);
          }
          assert(unaliasedDeclaration is ClassBuilder &&
              unaliasedDeclaration.name == "Null");
          return new Supertype(
              (unaliasedDeclaration as ClassBuilder).cls, const <DartType>[]);
        } else if (type is FutureOrType) {
          // Coverage-ignore-block(suite): Not run.
          // Even though `FutureOr` is disallowed as a supertype,
          // [ClassHierarchyBuilder] still expects it to be built to the
          // respective [InterfaceType] referencing the deprecated class. In
          // contrast with `Null`, it doesn't surface as an error due to
          // `FutureOr` class not having any inheritable members.
          // TODO(cstefantsova): Remove the dependency on the deprecated
          // FutureOr class from ClassHierarchyBuilder.
          TypeDeclarationBuilder? unaliasedDeclaration = this.declaration;
          // The following code assumes that the declaration is a
          // [TypeAliasBuilder] that through a chain of other
          // [TypeAliasBuilder]s (possibly, the chain length is 0) references a
          // [ClassBuilder] of the `FutureOr` class. Otherwise, it won't produce
          // the [FutureOrType] on the output.
          while (unaliasedDeclaration is TypeAliasBuilder) {
            unaliasedDeclaration = unaliasedDeclaration.type.declaration;
            assert(unaliasedDeclaration != null);
          }
          assert(unaliasedDeclaration is ClassBuilder &&
              unaliasedDeclaration.name == "FutureOr");
          return new Supertype((unaliasedDeclaration as ClassBuilder).cls,
              <DartType>[type.typeArgument]);
        }
        return _handleInvalidAliasedSupertype(library, aliasBuilder, type);
      case InvalidTypeDeclarationBuilder():
        library.addProblem(
            declaration.message.messageObject,
            declaration.message.charOffset,
            declaration.message.length,
            declaration.message.uri,
            severity: Severity.error);
        return null;
      case NominalVariableBuilder():
      case StructuralVariableBuilder():
      case ExtensionTypeDeclarationBuilder():
      case ExtensionBuilder():
      case BuiltinTypeDeclarationBuilder():
      // Coverage-ignore(suite): Not run.
      // TODO(johnniwinther): How should we handle this case?
      case OmittedTypeDeclarationBuilder():
    }
    return _handleInvalidSupertype(library);
  }

  @override
  Supertype? buildMixedInType(LibraryBuilder libraryBuilder) {
    TypeDeclarationBuilder declaration = this.declaration!;
    switch (declaration) {
      case ClassBuilder():
        if (libraryBuilder is SourceLibraryBuilder) {
          _checkDeferred(libraryBuilder, TypeUse.classWithType);
        }
        return declaration.buildMixedInType(libraryBuilder, typeArguments);
      case TypeAliasBuilder():
        TypeAliasBuilder aliasBuilder = declaration;
        DartType type = build(libraryBuilder, TypeUse.classWithType);
        if (type is InterfaceType && type.nullability != Nullability.nullable) {
          return new Supertype(type.classNode, type.typeArguments);
        }
        return _handleInvalidAliasedSupertype(
            libraryBuilder, aliasBuilder, type);
      case InvalidTypeDeclarationBuilder():
        libraryBuilder.addProblem(
            declaration.message.messageObject,
            declaration.message.charOffset,
            declaration.message.length,
            declaration.message.uri,
            severity: Severity.error);
        return null;
      case NominalVariableBuilder():
      case StructuralVariableBuilder():
      case ExtensionBuilder():
      case ExtensionTypeDeclarationBuilder():
      case BuiltinTypeDeclarationBuilder():
      // Coverage-ignore(suite): Not run.
      // TODO(johnniwinther): How should we handle this case?
      case OmittedTypeDeclarationBuilder():
    }
    return _handleInvalidSupertype(libraryBuilder);
  }

  @override
  NamedTypeBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    List<TypeBuilder>? clonedArguments;
    if (typeArguments != null) {
      clonedArguments =
          new List<TypeBuilder>.generate(typeArguments!.length, (int i) {
        return typeArguments![i]
            .clone(newTypes, contextLibrary, contextDeclaration);
      }, growable: false);
    }
    NamedTypeBuilderImpl newType = new NamedTypeBuilderImpl(
        typeName, nullabilityBuilder,
        arguments: clonedArguments,
        fileUri: fileUri,
        charOffset: charOffset,
        instanceTypeVariableAccess: _instanceTypeVariableAccess);
    if (declaration is BuiltinTypeDeclarationBuilder) {
      newType._declaration = declaration;
    } else {
      newTypes.add(newType);
    }
    return newType;
  }

  @override
  NamedTypeBuilder withNullabilityBuilder(
      NullabilityBuilder nullabilityBuilder) {
    return new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
        declaration!, nullabilityBuilder,
        arguments: typeArguments,
        fileUri: fileUri,
        charOffset: charOffset,
        instanceTypeVariableAccess: _instanceTypeVariableAccess);
  }

  /// Returns a copy of this named type using the provided type [arguments]
  /// instead of the original type arguments.
  @override
  NamedTypeBuilder withTypeArguments(List<TypeBuilder> arguments) {
    if (_declaration != null) {
      return new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
          _declaration!, nullabilityBuilder,
          arguments: arguments,
          fileUri: fileUri,
          charOffset: charOffset,
          instanceTypeVariableAccess: _instanceTypeVariableAccess);
    } else {
      return new NamedTypeBuilderImpl(typeName, nullabilityBuilder,
          arguments: arguments,
          fileUri: fileUri,
          charOffset: charOffset,
          instanceTypeVariableAccess: _instanceTypeVariableAccess);
    }
  }
}

/// A named type that is defined without the need for type inference.
///
/// This is the normal function type whose type arguments are either explicit or
/// omitted.
class _ExplicitNamedTypeBuilder extends NamedTypeBuilderImpl {
  DartType? _type;

  _ExplicitNamedTypeBuilder(
      TypeName name, NullabilityBuilder nullabilityBuilder,
      {List<TypeBuilder>? arguments,
      Uri? fileUri,
      int? charOffset,
      required InstanceTypeVariableAccessState instanceTypeVariableAccess})
      : super._(
            typeName: name,
            nullabilityBuilder: nullabilityBuilder,
            typeArguments: arguments,
            fileUri: fileUri,
            charOffset: charOffset,
            instanceTypeVariableAccess: instanceTypeVariableAccess);

  _ExplicitNamedTypeBuilder.forDartType(DartType type,
      TypeDeclarationBuilder declaration, NullabilityBuilder nullabilityBuilder,
      {List<TypeBuilder>? arguments})
      : _type = type,
        super._(
            declaration: declaration,
            typeName: new PredefinedTypeName(declaration.name),
            nullabilityBuilder: nullabilityBuilder,
            typeArguments: arguments,
            instanceTypeVariableAccess:
                InstanceTypeVariableAccessState.Unexpected,
            fileUri: null,
            charOffset: null);

  _ExplicitNamedTypeBuilder.fromTypeDeclarationBuilder(
      TypeDeclarationBuilder declaration, NullabilityBuilder nullabilityBuilder,
      {List<TypeBuilder>? arguments,
      Uri? fileUri,
      int? charOffset,
      required InstanceTypeVariableAccessState instanceTypeVariableAccess,
      DartType? type})
      : this._type = type,
        super._(
            typeName: new PredefinedTypeName(declaration.name),
            declaration: declaration,
            nullabilityBuilder: nullabilityBuilder,
            typeArguments: arguments,
            fileUri: fileUri,
            charOffset: charOffset,
            instanceTypeVariableAccess: instanceTypeVariableAccess);

  _ExplicitNamedTypeBuilder.forInvalidType(String name,
      NullabilityBuilder nullabilityBuilder, LocatedMessage message,
      {List<LocatedMessage>? context})
      : _type = const InvalidType(),
        super._(
            typeName: new PredefinedTypeName(name),
            nullabilityBuilder: nullabilityBuilder,
            declaration: new InvalidTypeDeclarationBuilder(name, message,
                context: context),
            fileUri: message.uri,
            charOffset: message.charOffset,
            instanceTypeVariableAccess:
                InstanceTypeVariableAccessState.Unexpected);

  @override
  bool get isExplicit => true;

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    return _type ??= _buildInternal(library, typeUse, hierarchy);
  }
}

// Coverage-ignore(suite): Not run.
/// A named type that needs type inference to be fully defined.
///
/// This occurs through macros where type arguments can be defined in terms of
/// inferred types, making this type indirectly depend on type inference.
class _InferredNamedTypeBuilder extends NamedTypeBuilderImpl
    with InferableTypeBuilderMixin {
  _InferredNamedTypeBuilder(
      TypeName name, NullabilityBuilder nullabilityBuilder,
      {List<TypeBuilder>? arguments,
      Uri? fileUri,
      int? charOffset,
      required InstanceTypeVariableAccessState instanceTypeVariableAccess})
      : super._(
            typeName: name,
            nullabilityBuilder: nullabilityBuilder,
            typeArguments: arguments,
            fileUri: fileUri,
            charOffset: charOffset,
            instanceTypeVariableAccess: instanceTypeVariableAccess);

  @override
  bool get isExplicit => false;

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    if (hasType) {
      return type;
    } else if (hierarchy != null) {
      return registerType(_buildInternal(library, typeUse, hierarchy));
    } else {
      InferableTypeUse inferableTypeUse =
          new InferableTypeUse(library as SourceLibraryBuilder, this, typeUse);
      library.registerInferableType(inferableTypeUse);
      return new InferredType.fromInferableTypeUse(inferableTypeUse);
    }
  }
}
