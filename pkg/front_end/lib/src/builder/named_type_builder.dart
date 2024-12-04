// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/bounds_checks.dart' show VarianceCalculationValue;
import 'package:kernel/src/unaliasing.dart' as unaliasing;
import 'package:kernel/type_algebra.dart';

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
        templateNotAPrefixInTypeAnnotation,
        templateNotAType,
        templateSupertypeIsIllegal,
        templateSupertypeIsIllegalAliased,
        templateSupertypeIsNullableAliased,
        templateSupertypeIsTypeParameter,
        templateTypeArgumentMismatch,
        templateTypeArgumentsOnTypeVariable,
        templateTypeNotFound;
import '../base/scope.dart';
import '../base/uris.dart';
import '../dill/dill_class_builder.dart';
import '../dill/dill_type_alias_builder.dart';
import '../kernel/implicit_field_type.dart';
import '../kernel/type_algorithms.dart';
import '../source/source_library_builder.dart';
import '../source/source_loader.dart';
import '../util/helpers.dart';
import 'builder.dart';
import 'declaration_builders.dart';
import 'inferable_type_builder.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'prefix_builder.dart';
import 'type_builder.dart';

/// Enum used to determine how instance type parameter access is allowed.
enum InstanceTypeParameterAccessState {
  /// Instance type parameter access is allowed.
  ///
  /// This is used for valid references to instance type parameters, like
  ///
  ///     class Class<T> {
  ///       void instanceMethod(T t) {}
  ///     }
  Allowed,

  /// Instance type parameter access is disallowed and results in a compile-time
  /// error.
  ///
  /// This is used for static references to instance type parameters, like
  ///
  ///     class Class<T> {
  ///       static void staticMethod(T t) {}
  ///     }
  ///
  /// The type is resolved as an [InvalidType].
  Disallowed,

  /// Instance type parameter access is invalid since it occurs in an invalid
  /// context. The occurrence _doesn't_ result in a compile-time error.
  ///
  /// This is used for references to instance type parameters where they might
  /// be valid if the context where, like
  ///
  ///     class Extension<T> {
  ///       T field; // Instance extension fields are not allowed.
  ///     }
  ///
  /// The type is resolved as an [InvalidType].
  Invalid,

  /// Instance type parameter access is unexpected and results in an assertion
  /// failure.
  ///
  /// This is used for [NamedTypeBuilder]s for known non-type parameter types,
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

  final InstanceTypeParameterAccessState _instanceTypeParameterAccess;

  final bool hasExplicitTypeArguments;

  /// Set to `true` if the type was resolved through a deferred import prefix.
  bool _isDeferred = false;

  factory NamedTypeBuilderImpl(
      TypeName name, NullabilityBuilder nullabilityBuilder,
      {List<TypeBuilder>? arguments,
      Uri? fileUri,
      int? charOffset,
      required InstanceTypeParameterAccessState instanceTypeParameterAccess}) {
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
            instanceTypeParameterAccess: instanceTypeParameterAccess)
        :
        // Coverage-ignore(suite): Not run.
        new _InferredNamedTypeBuilder(name, nullabilityBuilder,
            arguments: arguments,
            fileUri: fileUri,
            charOffset: charOffset,
            instanceTypeParameterAccess: instanceTypeParameterAccess);
  }

  NamedTypeBuilderImpl._(
      {required this.typeName,
      required this.nullabilityBuilder,
      this.typeArguments,
      this.fileUri,
      this.charOffset,
      required InstanceTypeParameterAccessState instanceTypeParameterAccess,
      TypeDeclarationBuilder? declaration})
      : this._instanceTypeParameterAccess = instanceTypeParameterAccess,
        this.hasExplicitTypeArguments = typeArguments != null,
        this._declaration = declaration;

  factory NamedTypeBuilderImpl.forDartType(
      DartType type,
      TypeDeclarationBuilder _declaration,
      NullabilityBuilder nullabilityBuilder,
      {List<TypeBuilder>? arguments,
      Uri? fileUri,
      int? charOffset}) = _ExplicitNamedTypeBuilder.forDartType;

  factory NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
      TypeDeclarationBuilder declaration, NullabilityBuilder nullabilityBuilder,
      {List<TypeBuilder>? arguments,
      Uri? fileUri,
      int? charOffset,
      required InstanceTypeParameterAccessState instanceTypeParameterAccess,
      DartType? type}) = _ExplicitNamedTypeBuilder.fromTypeDeclarationBuilder;

  factory NamedTypeBuilderImpl.forInvalidType(String name,
          NullabilityBuilder nullabilityBuilder, LocatedMessage message,
          {List<LocatedMessage>? context}) =
      _ExplicitNamedTypeBuilder.forInvalidType;

  @override
  TypeDeclarationBuilder get declaration {
    assert(_declaration != null, "Declaration has not been resolved on $this.");
    return _declaration!;
  }

  @override
  bool get isVoidType => false;

  @override
  void bind(
      ProblemReporting problemReporting, TypeDeclarationBuilder declaration) {
    _declaration = declaration.origin;
    _check(problemReporting);
  }

  @override
  void resolveIn(LookupScope scope, int charOffset, Uri fileUri,
      ProblemReporting problemReporting) {
    if (_declaration != null) return;
    Builder? member;
    String? qualifier = typeName.qualifier;
    if (qualifier != null) {
      Builder? prefix = scope.lookupGetable(qualifier, charOffset, fileUri);
      if (prefix is PrefixBuilder) {
        _isDeferred = prefix.deferred;
        member = prefix.lookup(typeName.name, typeName.nameOffset, fileUri);
      } else {
        // Attempt to use a member or type parameter as a prefix.
        int nameOffset = typeName.fullNameOffset;
        int nameLength = typeName.fullNameLength;
        Message message = templateNotAPrefixInTypeAnnotation.withArguments(
            qualifier, typeName.name);
        problemReporting.addProblem(message, nameOffset, nameLength, fileUri);
        bind(
            problemReporting,
            buildInvalidTypeDeclarationBuilder(
                message.withLocation(fileUri, nameOffset, nameLength)));
        return;
      }
    } else {
      member = scope.lookupGetable(typeName.name, typeName.nameOffset, fileUri);
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
              member.fileUri!, member.fileOffset, nameLength)
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
      if (_declaration!.isTypeParameter) {
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
      } else if (typeArguments!.length != declaration.typeParametersCount) {
        int nameOffset = typeName.nameOffset;
        int nameLength = typeName.nameLength;
        Message message = templateTypeArgumentMismatch
            .withArguments(declaration.typeParametersCount);
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
    } else if (_declaration is NominalParameterBuilder) {
      NominalParameterBuilder typeParameterBuilder =
          _declaration as NominalParameterBuilder;
      if (typeParameterBuilder.kind == TypeParameterKind.classMixinOrEnum ||
          typeParameterBuilder.kind ==
              TypeParameterKind.extensionOrExtensionType ||
          typeParameterBuilder.kind == TypeParameterKind.extensionSynthesized) {
        switch (_instanceTypeParameterAccess) {
          case InstanceTypeParameterAccessState.Disallowed:
            int nameOffset = typeName.nameOffset;
            int nameLength = typeName.nameLength;
            Message message = messageTypeVariableInStaticContext;
            problemReporting.addProblem(
                message, nameOffset, nameLength, fileUri);
            _declaration = buildInvalidTypeDeclarationBuilder(
                message.withLocation(fileUri!, nameOffset, nameLength));
            return;
          case InstanceTypeParameterAccessState.Invalid:
            int nameOffset = typeName.nameOffset;
            int nameLength = typeName.nameLength;
            Message message = messageTypeVariableInStaticContext;
            _declaration = buildInvalidTypeDeclarationBuilder(
                message.withLocation(fileUri!, nameOffset, nameLength));
            return;
          case InstanceTypeParameterAccessState.Unexpected:
            // Coverage-ignore(suite): Not run.
            assert(false,
                "Unexpected instance type parameter $typeParameterBuilder");
            break;
          case InstanceTypeParameterAccessState.Allowed:
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
        declaration.isTypeParameter
            ? templateSupertypeIsTypeParameter
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
    if (declaration.isTypeParameter) {
      // Coverage-ignore-block(suite): Not run.
      message =
          templateSupertypeIsTypeParameter.withArguments(fullNameForErrors);
    } else if (type.nullability == Nullability.nullable) {
      message = templateSupertypeIsNullableAliased.withArguments(
          fullNameForErrors, type);
    } else {
      message = templateSupertypeIsIllegalAliased.withArguments(
          fullNameForErrors, type);
    }
    library.addProblem(message, charOffset!, noLength, fileUri, context: [
      messageTypedefCause.withLocation(
          aliasBuilder.fileUri, aliasBuilder.fileOffset, noLength),
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
      List<StructuralParameterBuilder>? unboundTypeParameters}) {
    if (declaration is TypeAliasBuilder) {
      return (declaration as TypeAliasBuilder).unalias(typeArguments,
          usedTypeAliasBuilders: usedTypeAliasBuilders,
          unboundTypeParameters: unboundTypeParameters);
    }
    return this;
  }

  @override
  DartType buildAliased(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    assert(hierarchy != null || isExplicit, "Cannot build $this.");
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
    return declaration.buildAliasedType(
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
    TypeDeclarationBuilder declaration = this.declaration;
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
      case NominalParameterBuilder():
      case StructuralParameterBuilder():
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
    TypeDeclarationBuilder declaration = this.declaration;
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
      case NominalParameterBuilder():
      case StructuralParameterBuilder():
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
  NamedTypeBuilder withNullabilityBuilder(
      NullabilityBuilder nullabilityBuilder) {
    return new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
        declaration, nullabilityBuilder,
        arguments: typeArguments,
        fileUri: fileUri,
        charOffset: charOffset,
        instanceTypeParameterAccess: _instanceTypeParameterAccess);
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
          instanceTypeParameterAccess: _instanceTypeParameterAccess);
    } else {
      // Coverage-ignore-block(suite): Not run.
      return new NamedTypeBuilderImpl(typeName, nullabilityBuilder,
          arguments: arguments,
          fileUri: fileUri,
          charOffset: charOffset,
          instanceTypeParameterAccess: _instanceTypeParameterAccess);
    }
  }

  @override
  Nullability computeNullability(
      {required Map<TypeParameterBuilder, TraversalState>
          typeParametersTraversalState}) {
    return combineNullabilitiesForSubstitution(
        inner: declaration.computeNullabilityWithArguments(typeArguments,
            typeParametersTraversalState: typeParametersTraversalState),
        outer: nullabilityBuilder.build());
  }

  @override
  VarianceCalculationValue computeTypeParameterBuilderVariance(
      NominalParameterBuilder variable,
      {required SourceLoader sourceLoader}) {
    TypeDeclarationBuilder declaration = this.declaration;
    List<TypeBuilder>? arguments = this.typeArguments;
    switch (declaration) {
      case ClassBuilder():
        Variance result = Variance.unrelated;
        if (arguments != null) {
          for (int i = 0; i < arguments.length; ++i) {
            result = result.meet(declaration.cls.typeParameters[i].variance
                .combine(arguments[i]
                    .computeTypeParameterBuilderVariance(variable,
                        sourceLoader: sourceLoader)
                    .variance!));
          }
        }
        return new VarianceCalculationValue.fromVariance(result);
      case TypeAliasBuilder():
        Variance result = Variance.unrelated;

        if (arguments != null) {
          for (int i = 0; i < arguments.length; ++i) {
            NominalParameterBuilder declarationTypeParameter =
                declaration.typeParameters![i];
            VarianceCalculationValue? declarationTypeParameterVariance =
                declarationTypeParameter.varianceCalculationValue;
            if (declarationTypeParameterVariance == null ||
                declarationTypeParameterVariance ==
                    VarianceCalculationValue.pending) {
              assert(!declaration.fromDill);
              declarationTypeParameter.varianceCalculationValue =
                  VarianceCalculationValue.inProgress;
              Variance computedVariance = declaration.type
                  .computeTypeParameterBuilderVariance(declarationTypeParameter,
                      sourceLoader: sourceLoader)
                  .variance!;

              declarationTypeParameter.varianceCalculationValue =
                  declarationTypeParameterVariance =
                      new VarianceCalculationValue.fromVariance(
                          computedVariance);
            } else if (declarationTypeParameterVariance ==
                VarianceCalculationValue.inProgress) {
              assert(!declaration.fromDill);
              NominalParameterBuilder declarationTypeParameter =
                  declaration.typeParameters![i];
              // Cyclic type alias.
              assert(sourceLoader.assertProblemReportedElsewhere(
                  "computeTypeParameterBuilderVariance: Cyclic type alias.",
                  expectedPhase: CompilationPhaseForProblemReporting.outline));

              // Use [Variance.unrelated] for recovery.  The type with the
              // cyclic dependency will be replaced with an [InvalidType]
              // elsewhere.
              declarationTypeParameter.varianceCalculationValue =
                  declarationTypeParameterVariance =
                      new VarianceCalculationValue.fromVariance(
                          Variance.unrelated);
              declarationTypeParameter.variance = Variance.unrelated;
            }

            result = result.meet(arguments[i]
                .computeTypeParameterBuilderVariance(variable,
                    sourceLoader: sourceLoader)
                .variance!
                .combine(declarationTypeParameterVariance.variance!));
          }
        }
        return new VarianceCalculationValue.fromVariance(result);
      case ExtensionTypeDeclarationBuilder():
        Variance result = Variance.unrelated;
        if (arguments != null) {
          for (int i = 0; i < arguments.length; ++i) {
            result = result.meet(declaration
                .extensionTypeDeclaration.typeParameters[i].variance
                .combine(arguments[i]
                    .computeTypeParameterBuilderVariance(variable,
                        sourceLoader: sourceLoader)
                    .variance!));
          }
        }
        return new VarianceCalculationValue.fromVariance(result);
      case NominalParameterBuilder():
        if (declaration == variable) {
          return VarianceCalculationValue.calculatedCovariant;
        } else {
          return VarianceCalculationValue.calculatedUnrelated;
        }
      case StructuralParameterBuilder():
      case ExtensionBuilder():
      case InvalidTypeDeclarationBuilder():
      case BuiltinTypeDeclarationBuilder():
      // Coverage-ignore(suite): Not run.
      // TODO(johnniwinther): How should we handle this case?
      case OmittedTypeDeclarationBuilder():
    }
    return VarianceCalculationValue.calculatedUnrelated;
  }

  @override
  TypeDeclarationBuilder? computeUnaliasedDeclaration(
      {required bool isUsedAsClass}) {
    TypeDeclarationBuilder? declaration = this.declaration;
    if (declaration is TypeAliasBuilder) {
      declaration = declaration.unaliasDeclaration(typeArguments,
          isUsedAsClass: isUsedAsClass,
          usedAsClassCharOffset: charOffset,
          usedAsClassFileUri: fileUri);
    }
    return declaration;
  }

  @override
  void collectReferencesFrom(Map<TypeParameterBuilder, int> parameterIndices,
      List<List<int>> edges, int index) {
    TypeDeclarationBuilder declaration = this.declaration;
    List<TypeBuilder>? arguments = this.typeArguments;
    if (declaration is NominalParameterBuilder &&
        parameterIndices.containsKey(declaration)) {
      edges[parameterIndices[declaration]!].add(index);
    }
    if (arguments != null) {
      for (TypeBuilder argument in arguments) {
        argument.collectReferencesFrom(parameterIndices, edges, index);
      }
    }
  }

  @override
  TypeBuilder? substituteRange(
      Map<TypeParameterBuilder, TypeBuilder> upperSubstitution,
      Map<TypeParameterBuilder, TypeBuilder> lowerSubstitution,
      List<StructuralParameterBuilder> unboundTypeParameters,
      {final Variance variance = Variance.covariant}) {
    TypeDeclarationBuilder declaration = this.declaration;
    List<TypeBuilder>? arguments = this.typeArguments;

    if (declaration is TypeParameterBuilder) {
      if (variance == Variance.contravariant) {
        TypeBuilder? replacement = lowerSubstitution[declaration];
        if (replacement != null) {
          return replacement.withNullabilityBuilder(
              combineNullabilityBuildersForSubstitution(
                  replacement.nullabilityBuilder, nullabilityBuilder));
        }
        return null;
      } else {
        TypeBuilder? replacement = upperSubstitution[declaration];
        if (replacement != null) {
          return replacement.withNullabilityBuilder(
              combineNullabilityBuildersForSubstitution(
                  replacement.nullabilityBuilder, nullabilityBuilder));
        }
        return null;
      }
    }
    if (arguments == null || arguments.length == 0) {
      return null;
    }

    List<TypeBuilder>? newArguments;
    switch (declaration) {
      case ClassBuilder():
        for (int i = 0; i < arguments.length; ++i) {
          TypeBuilder? substitutedArgument = arguments[i].substituteRange(
              upperSubstitution, lowerSubstitution, unboundTypeParameters,
              variance: variance);
          if (substitutedArgument != null) {
            newArguments ??= arguments.toList();
            newArguments[i] = substitutedArgument;
          }
        }
      case ExtensionTypeDeclarationBuilder():
        for (int i = 0; i < arguments.length; ++i) {
          TypeBuilder? substitutedArgument = arguments[i].substituteRange(
              upperSubstitution, lowerSubstitution, unboundTypeParameters,
              variance: variance);
          if (substitutedArgument != null) {
            newArguments ??= arguments.toList();
            newArguments[i] = substitutedArgument;
          }
        }
      case TypeAliasBuilder():
        for (int i = 0; i < arguments.length; ++i) {
          NominalParameterBuilder variable = declaration.typeParameters![i];
          TypeBuilder? substitutedArgument = arguments[i].substituteRange(
              upperSubstitution, lowerSubstitution, unboundTypeParameters,
              variance: variance.combine(variable.variance));
          if (substitutedArgument != null) {
            newArguments ??= arguments.toList();
            newArguments[i] = substitutedArgument;
          }
        }
      // Coverage-ignore(suite): Not run.
      case NominalParameterBuilder():
        // Handled above.
        throw new UnsupportedError("Unexpected NominalVariableBuilder");
      // Coverage-ignore(suite): Not run.
      case StructuralParameterBuilder():
        // Handled above.
        throw new UnsupportedError("Unexpected StructuralVariableBuilder");
      // Coverage-ignore(suite): Not run.
      case InvalidTypeDeclarationBuilder():
        // Don't substitute.
        break;
      // Coverage-ignore(suite): Not run.
      case ExtensionBuilder():
      case BuiltinTypeDeclarationBuilder():
      // TODO(johnniwinther): How should we handle this case?
      case OmittedTypeDeclarationBuilder():
        assert(
            false, "Unexpected named type builder declaration: $declaration.");
    }
    if (newArguments != null) {
      return withTypeArguments(newArguments);
    }
    return null;
  }

  @override
  TypeBuilder? unaliasAndErase() {
    TypeDeclarationBuilder declaration = this.declaration;
    if (declaration is TypeAliasBuilder) {
      // We pass empty lists as [unboundTypes] and [unboundTypeParameters]
      // because new builders can be generated during unaliasing. We ignore
      // the returned builders, however, because they will not be used in the
      // output and are needed only for the checks.
      //
      // We also don't instantiate-to-bound raw types because it won't affect
      // the dependency cycle analysis.
      return declaration
          .unalias(typeArguments, unboundTypeParameters: [])?.unaliasAndErase();
    } else if (declaration is ExtensionTypeDeclarationBuilder) {
      TypeBuilder? representationType =
          declaration.declaredRepresentationTypeBuilder;
      if (representationType == null) {
        return null;
      } else {
        List<NominalParameterBuilder>? typeParameters =
            declaration.typeParameters;
        List<TypeBuilder>? typeArguments = this.typeArguments;
        if (typeParameters != null && typeArguments != null) {
          representationType = representationType.subst(
              new Map<NominalParameterBuilder, TypeBuilder>.fromIterables(
                  typeParameters, typeArguments));
        }
        return representationType.unaliasAndErase();
      }
    } else {
      return this;
    }
  }

  @override
  bool usesTypeParameters(Set<String> typeParameterNames) {
    if (typeParameterNames.contains(typeName.name)) {
      return true;
    }
    if (typeArguments != null) {
      for (TypeBuilder argument in typeArguments!) {
        if (argument.usesTypeParameters(typeParameterNames)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  List<TypeWithInBoundReferences> findRawTypesWithInboundReferences() {
    List<TypeWithInBoundReferences> typesAndDependencies = [];
    TypeDeclarationBuilder declaration = this.declaration;
    List<TypeBuilder>? arguments = this.typeArguments;
    if (arguments == null) {
      switch (declaration) {
        case ClassBuilder():
          if (declaration is DillClassBuilder) {
            bool hasInbound = false;
            List<TypeParameter> typeParameters = declaration.cls.typeParameters;
            for (int i = 0; i < typeParameters.length && !hasInbound; ++i) {
              if (containsTypeParameter(
                  typeParameters[i].bound, typeParameters.toSet())) {
                hasInbound = true;
              }
            }
            if (hasInbound) {
              typesAndDependencies
                  .add(new TypeWithInBoundReferences(this, const []));
            }
          } else if (declaration.typeParameters != null) {
            List<InBoundReferences> dependencies =
                findInboundReferences(declaration.typeParameters!);
            if (dependencies.length != 0) {
              typesAndDependencies
                  .add(new TypeWithInBoundReferences(this, dependencies));
            }
          }
        case TypeAliasBuilder():
          if (declaration is DillTypeAliasBuilder) {
            bool hasInbound = false;
            List<TypeParameter> typeParameters =
                declaration.typedef.typeParameters;
            for (int i = 0; i < typeParameters.length && !hasInbound; ++i) {
              if (containsTypeParameter(
                  typeParameters[i].bound, typeParameters.toSet())) {
                hasInbound = true;
              }
            }
            if (hasInbound) {
              // Coverage-ignore-block(suite): Not run.
              typesAndDependencies
                  .add(new TypeWithInBoundReferences(this, const []));
            }
          } else {
            if (declaration.typeParameters != null) {
              List<InBoundReferences> dependencies =
                  findInboundReferences(declaration.typeParameters!);
              if (dependencies.length != 0) {
                typesAndDependencies
                    .add(new TypeWithInBoundReferences(this, dependencies));
              }
            }
            if (declaration.type is FunctionTypeBuilder) {
              FunctionTypeBuilder type =
                  declaration.type as FunctionTypeBuilder;
              if (type.typeParameters != null) {
                List<InBoundReferences> dependencies =
                    findInboundReferences(type.typeParameters!);
                if (dependencies.length != 0) {
                  // Coverage-ignore-block(suite): Not run.
                  typesAndDependencies
                      .add(new TypeWithInBoundReferences(type, dependencies));
                }
              }
            }
          }
        case ExtensionTypeDeclarationBuilder():
          if (declaration.typeParameters != null) {
            List<InBoundReferences> dependencies =
                findInboundReferences(declaration.typeParameters!);
            if (dependencies.length != 0) {
              // Coverage-ignore-block(suite): Not run.
              typesAndDependencies
                  .add(new TypeWithInBoundReferences(this, dependencies));
            }
          }
        case NominalParameterBuilder():
        case StructuralParameterBuilder():
        case ExtensionBuilder():
        case InvalidTypeDeclarationBuilder():
        case BuiltinTypeDeclarationBuilder():
        // Coverage-ignore(suite): Not run.
        // TODO(johnniwinther): How should we handle this case?
        case OmittedTypeDeclarationBuilder():
      }
    } else {
      for (TypeBuilder argument in arguments) {
        typesAndDependencies
            .addAll(argument.findRawTypesWithInboundReferences());
      }
    }
    return typesAndDependencies;
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
      required InstanceTypeParameterAccessState instanceTypeParameterAccess})
      : super._(
            typeName: name,
            nullabilityBuilder: nullabilityBuilder,
            typeArguments: arguments,
            fileUri: fileUri,
            charOffset: charOffset,
            instanceTypeParameterAccess: instanceTypeParameterAccess);

  _ExplicitNamedTypeBuilder.forDartType(DartType type,
      TypeDeclarationBuilder declaration, NullabilityBuilder nullabilityBuilder,
      {List<TypeBuilder>? arguments, Uri? fileUri, int? charOffset})
      : _type = type,
        super._(
            declaration: declaration,
            typeName: new PredefinedTypeName(declaration.name),
            nullabilityBuilder: nullabilityBuilder,
            typeArguments: arguments,
            instanceTypeParameterAccess:
                InstanceTypeParameterAccessState.Unexpected,
            fileUri: fileUri,
            charOffset: charOffset);

  _ExplicitNamedTypeBuilder.fromTypeDeclarationBuilder(
      TypeDeclarationBuilder declaration, NullabilityBuilder nullabilityBuilder,
      {List<TypeBuilder>? arguments,
      Uri? fileUri,
      int? charOffset,
      required InstanceTypeParameterAccessState instanceTypeParameterAccess,
      DartType? type})
      : this._type = type,
        super._(
            typeName: new PredefinedTypeName(declaration.name),
            declaration: declaration,
            nullabilityBuilder: nullabilityBuilder,
            typeArguments: arguments,
            fileUri: fileUri,
            charOffset: charOffset,
            instanceTypeParameterAccess: instanceTypeParameterAccess);

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
            instanceTypeParameterAccess:
                InstanceTypeParameterAccessState.Unexpected);

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
      required InstanceTypeParameterAccessState instanceTypeParameterAccess})
      : super._(
            typeName: name,
            nullabilityBuilder: nullabilityBuilder,
            typeArguments: arguments,
            fileUri: fileUri,
            charOffset: charOffset,
            instanceTypeParameterAccess: instanceTypeParameterAccess);

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
      library.loader.inferableTypes.registerInferableType(inferableTypeUse);
      return new InferredType.fromInferableTypeUse(inferableTypeUse);
    }
  }
}
