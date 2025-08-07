// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/metadata/expressions.dart' as shared;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

import '../../base/constant_context.dart';
import '../../base/messages.dart';
import '../../base/problems.dart';
import '../../base/scope.dart';
import '../../base/uri_offset.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/metadata_builder.dart';
import '../../builder/omitted_type_builder.dart';
import '../../builder/property_builder.dart';
import '../../builder/type_builder.dart';
import '../../kernel/body_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/hierarchy/class_member.dart';
import '../../kernel/hierarchy/members_builder.dart';
import '../../kernel/implicit_field_type.dart';
import '../../kernel/late_lowering.dart' as late_lowering;
import '../../kernel/macro/metadata.dart';
import '../../kernel/type_algorithms.dart';
import '../../source/name_scheme.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_member_builder.dart';
import '../../source/source_property_builder.dart';
import '../../source/type_parameter_factory.dart';
import '../../type_inference/inference_helper.dart';
import '../../type_inference/type_inference_engine.dart';
import '../../type_inference/type_inferrer.dart';
import '../fragment.dart';
import '../getter/declaration.dart';
import '../setter/declaration.dart';

/// Common interface for fragments that can declare a field.
abstract class FieldDeclaration {
  UriOffsetLength? get uriOffset;

  FieldQuality get fieldQuality;

  /// The metadata declared on this fragment.
  List<MetadataBuilder>? get metadata;

  /// Builds the core AST structures for this field declaration as needed for
  /// the outline.
  void buildFieldOutlineNode(
      SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme,
      BuildNodesCallback f,
      PropertyReferences references,
      {required List<TypeParameter>? classTypeParameters});

  void buildFieldOutlineExpressions(
      {required ClassHierarchy classHierarchy,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required List<Annotatable> annotatables,
      required Uri annotatablesFileUri,
      required bool isClassInstanceMember});

  int computeFieldDefaultTypes(ComputeDefaultTypeContext context);

  void createFieldEncoding(SourcePropertyBuilder builder);

  void checkFieldTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder);

  /// Checks the variance of type parameters [sourceClassBuilder] used in the
  /// type of this field declaration.
  void checkFieldVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment);

  /// Return `true` if the declaration introduces a setter.
  bool get hasSetter;

  /// Return `true` if the declaration has an initializer.
  bool get hasInitializer;

  /// Return `true` if the declaration is final.
  bool get isFinal;

  /// Return `true` if the declaration is late.
  bool get isLate;

  /// Return `true` if the declaration is in instance field declared in an
  /// extension type.
  bool get isExtensionTypeDeclaredInstanceField;

  /// Returns `true` if this field is declared by an enum element.
  bool get isEnumElement;

  /// Returns `true` if the declaration is const.
  bool get isConst;

  /// The [DartType] of this field declaration.
  abstract DartType fieldType;

  /// Creates the [Initializer] for the invalid initialization of this field.
  ///
  /// This is only used for instance fields.
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset});

  /// Creates the AST node for this field as the default initializer.
  ///
  /// This is only used for instance fields.
  void buildImplicitDefaultValue();

  /// Creates the [Initializer] for the implicit initialization of this field
  /// in a constructor.
  ///
  /// This is only used for instance fields.
  Initializer buildImplicitInitializer();

  /// Builds the [Initializer]s for each field used to encode this field
  /// using the [fileOffset] for the created nodes and [value] as the initial
  /// field value.
  ///
  /// This is only used for instance fields.
  List<Initializer> buildInitializer(int fileOffset, Expression value,
      {required bool isSynthetic});

  /// Ensures that the type of this field declaration has been computed.
  void ensureTypes(
      ClassMembersBuilder membersBuilder,
      Set<ClassMember>? getterOverrideDependencies,
      Set<ClassMember>? setterOverrideDependencies);

  /// Infers the type of this field declaration.
  DartType inferType(ClassHierarchyBase hierarchy);

  shared.Expression? get initializerExpression;
}

class RegularFieldDeclaration
    with FieldDeclarationMixin
    implements
        FieldDeclaration,
        FieldFragmentDeclaration,
        GetterDeclaration,
        SetterDeclaration,
        Inferable,
        InferredTypeListener {
  final FieldFragment _fragment;

  late final FieldEncoding _encoding;

  shared.Expression? _initializerExpression;

  /// Whether the body of this field has been built.
  ///
  /// Constant fields have their initializer built in the outline so we avoid
  /// building them twice as part of the non-outline build.
  bool hasBodyBeenBuilt = false;

  RegularFieldDeclaration(this._fragment) {
    _fragment.declaration = this;
  }

  @override
  UriOffsetLength get uriOffset => _fragment.uriOffset;

  @override
  SourcePropertyBuilder get builder => _fragment.builder;

  @override
  FieldQuality get fieldQuality => _fragment.modifiers.isAbstract
      ? FieldQuality.Abstract
      : _fragment.modifiers.isExternal
          ? FieldQuality.External
          : FieldQuality.Concrete;

  @override
  DartType get fieldType => _encoding.type;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  GetterQuality get getterQuality => _fragment.modifiers.isAbstract
      ? GetterQuality.ImplicitAbstract
      : _fragment.modifiers.isExternal
          ? GetterQuality.ImplicitExternal
          : GetterQuality.Implicit;

  @override
  bool get hasInitializer => _fragment.modifiers.hasInitializer;

  @override
  bool get hasSetter => _fragment.hasSetter;

  @override
  // Coverage-ignore(suite): Not run.
  shared.Expression? get initializerExpression => _initializerExpression;

  @override
  bool get isConst => _fragment.modifiers.isConst;

  @override
  bool get isEnumElement => false;

  @override
  bool get isExtensionTypeDeclaredInstanceField =>
      builder.isExtensionTypeInstanceMember;

  @override
  bool get isFinal => _fragment.modifiers.isFinal;

  @override
  bool get isLate => _fragment.modifiers.isLate;

  @override
  bool get isStatic =>
      _fragment.modifiers.isStatic || builder.declarationBuilder == null;

  @override
  List<ClassMember> get localMembers => _encoding.localMembers;

  @override
  List<ClassMember> get localSetters => _encoding.localSetters;

  @override
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  Member get readTarget => _encoding.readTarget;

  @override
  SetterQuality get setterQuality => !hasSetter
      ? SetterQuality.Absent
      : _fragment.modifiers.isAbstract
          ? SetterQuality.ImplicitAbstract
          : _fragment.modifiers.isExternal
              ? SetterQuality.ImplicitExternal
              : SetterQuality.Implicit;

  @override
  TypeBuilder get type => _fragment.type;

  @override
  Member? get writeTarget => _encoding.writeTarget;

  @override
  // Coverage-ignore(suite): Not run.
  DartType get fieldTypeInternal => _encoding.type;

  @override
  void set fieldTypeInternal(DartType value) {
    _encoding.type = value;
  }

  /// Builds the body of this field using [initializer] as the initializer
  /// expression.
  void buildBody(CoreTypes coreTypes, Expression? initializer) {
    assert(!hasBodyBeenBuilt, "Body has already been built for $this.");
    hasBodyBeenBuilt = true;
    if (!_fragment.modifiers.hasInitializer &&
        initializer != null &&
        initializer is! NullLiteral &&
        // Coverage-ignore(suite): Not run.
        !_fragment.modifiers.isConst &&
        // Coverage-ignore(suite): Not run.
        !_fragment.modifiers.isFinal) {
      internalProblem(
          codeInternalProblemAlreadyInitialized, nameOffset, fileUri);
    }
    _encoding.createBodies(coreTypes, initializer);
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    return _encoding.buildErroneousInitializer(effect, value,
        fileOffset: fileOffset);
  }

  @override
  void buildFieldInitializer(InferenceHelper helper, TypeInferrer typeInferrer,
      CoreTypes coreTypes, Expression? initializer) {
    if (initializer != null) {
      if (!hasBodyBeenBuilt) {
        initializer = typeInferrer
            .inferFieldInitializer(helper, fieldType, initializer)
            .expression;
        buildBody(coreTypes, initializer);
      }
    } else if (!hasBodyBeenBuilt) {
      buildBody(coreTypes, null);
    }
  }

  @override
  void buildImplicitDefaultValue() {
    _encoding.buildImplicitDefaultValue();
  }

  @override
  Initializer buildImplicitInitializer() {
    return _encoding.buildImplicitInitializer();
  }

  @override
  List<Initializer> buildInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    return _encoding.createInitializer(fileOffset, value,
        isSynthetic: isSynthetic);
  }

  @override
  void buildFieldOutlineExpressions(
      {required ClassHierarchy classHierarchy,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required List<Annotatable> annotatables,
      required Uri annotatablesFileUri,
      required bool isClassInstanceMember}) {
    BodyBuilderContext bodyBuilderContext = createBodyBuilderContext();
    for (Annotatable annotatable in annotatables) {
      buildMetadataForOutlineExpressions(
          libraryBuilder: libraryBuilder,
          scope: _fragment.enclosingScope,
          bodyBuilderContext: bodyBuilderContext,
          annotatable: annotatable,
          annotatableFileUri: annotatablesFileUri,
          metadata: metadata);
    }
    // For modular compilation we need to include initializers of all const
    // fields and all non-static final fields in classes with const constructors
    // into the outline.
    Token? token = _fragment.constInitializerToken;
    if ((_fragment.modifiers.isConst ||
            (isFinal &&
                isClassInstanceMember &&
                (declarationBuilder as SourceClassBuilder)
                    .declaresConstConstructor)) &&
        token != null) {
      LookupScope scope = _fragment.enclosingScope;
      BodyBuilder bodyBuilder = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(
              libraryBuilder, createBodyBuilderContext(), scope, fileUri);
      bodyBuilder.constantContext = _fragment.modifiers.isConst
          ? ConstantContext.inferred
          : ConstantContext.required;
      Expression initializer = bodyBuilder.typeInferrer
          .inferFieldInitializer(
              bodyBuilder, fieldType, bodyBuilder.parseFieldInitializer(token))
          .expression;
      buildBody(classHierarchy.coreTypes, initializer);
      bodyBuilder.performBacklogComputations();
      if (computeSharedExpressionForTesting) {
        // Coverage-ignore-block(suite): Not run.
        _initializerExpression = parseFieldInitializer(libraryBuilder.loader,
            token, libraryBuilder.importUri, fileUri, scope);
      }
    }
  }

  @override
  void buildFieldOutlineNode(
      SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme,
      BuildNodesCallback f,
      PropertyReferences references,
      {required List<TypeParameter>? classTypeParameters}) {
    _encoding.buildOutlineNode(libraryBuilder, nameScheme, references,
        isAbstractOrExternal:
            _fragment.modifiers.isAbstract || _fragment.modifiers.isExternal,
        classTypeParameters: classTypeParameters);
    if (type is! InferableTypeBuilder) {
      fieldType = type.build(libraryBuilder, TypeUse.fieldType);
    }
    _encoding.registerMembers(f);
  }

  @override
  void checkFieldTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder) {
    libraryBuilder.checkTypesInField(typeEnvironment,
        isInstanceMember: builder.isDeclarationInstanceMember,
        isLate: isLate,
        isExternal: _fragment.modifiers.isExternal,
        hasInitializer: hasInitializer,
        fieldType: fieldType,
        name: _fragment.name,
        nameLength: _fragment.name.length,
        nameOffset: nameOffset,
        fileUri: fileUri);
  }

  @override
  void checkFieldVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    sourceClassBuilder.checkVarianceInField(typeEnvironment,
        fieldType: fieldType,
        isInstanceMember: !isStatic,
        hasSetter: hasSetter,
        isCovariantByDeclaration: _fragment.modifiers.isCovariant,
        fileUri: fileUri,
        fileOffset: nameOffset);
  }

  @override
  int computeFieldDefaultTypes(ComputeDefaultTypeContext context) {
    if (type is! OmittedTypeBuilder) {
      context.reportInboundReferenceIssuesForType(type);
      context.recursivelyReportGenericFunctionTypesAsBoundsForType(type);
    }
    return 0;
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    return new FieldFragmentBodyBuilderContext(builder, this,
        isLateField: _fragment.modifiers.isLate,
        isAbstractField: _fragment.modifiers.isAbstract,
        isExternalField: _fragment.modifiers.isExternal,
        nameOffset: _fragment.nameOffset,
        nameLength: _fragment.name.length,
        isConst: _fragment.modifiers.isConst);
  }

  @override
  void createFieldEncoding(SourcePropertyBuilder builder) {
    _fragment.builder = builder;

    SourceLibraryBuilder libraryBuilder = builder.libraryBuilder;

    bool isAbstract = _fragment.modifiers.isAbstract;
    bool isExternal = _fragment.modifiers.isExternal;
    bool isInstanceMember = builder.isDeclarationInstanceMember;
    bool isExtensionMember = builder.isExtensionMember;
    bool isExtensionTypeMember = builder.isExtensionTypeMember;

    // If in mixed mode, late lowerings cannot use `null` as a sentinel on
    // non-nullable fields since they can be assigned from legacy code.
    late_lowering.IsSetStrategy isSetStrategy =
        late_lowering.computeIsSetStrategy(libraryBuilder);
    if (isAbstract || isExternal) {
      _encoding = new AbstractOrExternalFieldEncoding(_fragment,
          isExtensionInstanceMember: isExtensionMember && isInstanceMember,
          isExtensionTypeInstanceMember:
              isExtensionTypeMember && isInstanceMember,
          isAbstract: isAbstract,
          isExternal: isExternal);
    } else if (isExtensionTypeMember && isInstanceMember) {
      // Field on a extension type. Encode as abstract.
      // TODO(johnniwinther): Should we have an erroneous flag on such
      // members?
      _encoding = new AbstractOrExternalFieldEncoding(_fragment,
          isExtensionInstanceMember: isExtensionMember && isInstanceMember,
          isExtensionTypeInstanceMember:
              isExtensionTypeMember && isInstanceMember,
          isAbstract: true,
          isExternal: false,
          isForcedExtension: true);
    } else if (isLate &&
        libraryBuilder.loader.target.backendTarget.isLateFieldLoweringEnabled(
            hasInitializer: hasInitializer,
            isFinal: isFinal,
            isStatic: !isInstanceMember)) {
      if (hasInitializer) {
        if (isFinal) {
          _encoding = new LateFinalFieldWithInitializerEncoding(_fragment,
              isSetStrategy: isSetStrategy);
        } else {
          _encoding = new LateFieldWithInitializerEncoding(_fragment,
              isSetStrategy: isSetStrategy);
        }
      } else {
        if (isFinal) {
          _encoding = new LateFinalFieldWithoutInitializerEncoding(_fragment,
              isSetStrategy: isSetStrategy);
        } else {
          _encoding = new LateFieldWithoutInitializerEncoding(_fragment,
              isSetStrategy: isSetStrategy);
        }
      }
    } else if (libraryBuilder
            .loader.target.backendTarget.useStaticFieldLowering &&
        !isInstanceMember &&
        !_fragment.modifiers.isConst &&
        hasInitializer) {
      if (isFinal) {
        _encoding = new LateFinalFieldWithInitializerEncoding(_fragment,
            isSetStrategy: isSetStrategy);
      } else {
        _encoding = new LateFieldWithInitializerEncoding(_fragment,
            isSetStrategy: isSetStrategy);
      }
    } else {
      _encoding = new RegularFieldEncoding(_fragment, isEnumElement: false);
    }

    type.registerInferredTypeListener(this);
    Token? token = _fragment.initializerToken;
    if (type is InferableTypeBuilder) {
      if (!_fragment.modifiers.hasInitializer && isStatic) {
        // A static field without type and initializer will always be inferred
        // to have type `dynamic`.
        type.registerInferredType(const DynamicType());
      } else {
        // A field with no type and initializer or an instance field without
        // type and initializer need to have the type inferred.
        _encoding.type = new InferredType(
            libraryBuilder: libraryBuilder,
            typeBuilder: type,
            inferType: inferType,
            computeType: _computeInferredType,
            fileUri: fileUri,
            name: _fragment.name,
            nameOffset: nameOffset,
            nameLength: _fragment.name.length,
            token: token);
        type.registerInferable(this);
      }
    }
  }

  @override
  void ensureTypes(
      ClassMembersBuilder membersBuilder,
      Set<ClassMember>? getterOverrideDependencies,
      Set<ClassMember>? setterOverrideDependencies) {
    if (getterOverrideDependencies != null ||
        setterOverrideDependencies != null) {
      membersBuilder.inferFieldType(
          builder.declarationBuilder as SourceClassBuilder,
          type,
          [...?getterOverrideDependencies, ...?setterOverrideDependencies],
          name: _fragment.name,
          fileUri: fileUri,
          nameOffset: nameOffset,
          nameLength: _fragment.name.length,
          isAssignable: hasSetter);
    } else {
      // Coverage-ignore-block(suite): Not run.
      type.build(builder.libraryBuilder, TypeUse.fieldType,
          hierarchy: membersBuilder.hierarchyBuilder);
    }
  }

  @override
  void registerSuperCall() {
    _encoding.registerSuperCall();
  }

  DartType _computeInferredType(
      ClassHierarchyBase classHierarchy, Token? token) {
    DartType? inferredType;
    SourceLibraryBuilder libraryBuilder = builder.libraryBuilder;
    DeclarationBuilder? declarationBuilder = builder.declarationBuilder;
    if (token != null) {
      InterfaceType? enclosingClassThisType = declarationBuilder
              is SourceClassBuilder
          ? libraryBuilder.loader.typeInferenceEngine.coreTypes
              .thisInterfaceType(
                  declarationBuilder.cls, libraryBuilder.library.nonNullable)
          : null;
      LookupScope scope = _fragment.enclosingScope;
      TypeInferrer typeInferrer =
          libraryBuilder.loader.typeInferenceEngine.createTopLevelTypeInferrer(
              fileUri,
              enclosingClassThisType,
              libraryBuilder,
              scope,
              builder
                  .dataForTesting
                  // Coverage-ignore(suite): Not run.
                  ?.inferenceData);
      BodyBuilderContext bodyBuilderContext = createBodyBuilderContext();
      BodyBuilder bodyBuilder = libraryBuilder.loader.createBodyBuilderForField(
          libraryBuilder, bodyBuilderContext, scope, typeInferrer, fileUri);
      bodyBuilder.constantContext = _fragment.modifiers.isConst
          ? ConstantContext.inferred
          : ConstantContext.none;
      bodyBuilder.inFieldInitializer = true;
      bodyBuilder.inLateFieldInitializer = _fragment.modifiers.isLate;
      Expression initializer = bodyBuilder.parseFieldInitializer(token);

      inferredType =
          typeInferrer.inferImplicitFieldType(bodyBuilder, initializer);
    } else {
      inferredType = const DynamicType();
    }
    return inferredType;
  }

  @override
  void setCovariantByClassInternal() {
    _encoding.setCovariantByClass();
  }

  @override
  void buildGetterOutlineExpressions(
      {required ClassHierarchy classHierarchy,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required SourcePropertyBuilder propertyBuilder,
      required Annotatable annotatable,
      required Uri annotatableFileUri,
      required bool isClassInstanceMember}) {}

  @override
  void buildGetterOutlineNode(
      {required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required BuildNodesCallback f,
      required PropertyReferences? references,
      required List<TypeParameter>? classTypeParameters}) {}

  @override
  void buildSetterOutlineExpressions(
      {required ClassHierarchy classHierarchy,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required SourcePropertyBuilder propertyBuilder,
      required Annotatable annotatable,
      required Uri annotatableFileUri,
      required bool isClassInstanceMember}) {}

  @override
  void buildSetterOutlineNode(
      {required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required BuildNodesCallback f,
      required PropertyReferences? references,
      required List<TypeParameter>? classTypeParameters}) {}

  @override
  void checkGetterTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder) {}

  @override
  void checkGetterVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkSetterTypes(
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkSetterVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  int computeGetterDefaultTypes(ComputeDefaultTypeContext context) {
    return 0;
  }

  @override
  int computeSetterDefaultTypes(ComputeDefaultTypeContext context) {
    return 0;
  }

  @override
  void createGetterEncoding(
      ProblemReporting problemReporting,
      SourcePropertyBuilder builder,
      PropertyEncodingStrategy encodingStrategy,
      TypeParameterFactory typeParameterFactory) {}

  @override
  void createSetterEncoding(
      ProblemReporting problemReporting,
      SourcePropertyBuilder builder,
      PropertyEncodingStrategy encodingStrategy,
      TypeParameterFactory typeParameterFactory) {}

  @override
  void ensureGetterTypes(
      {required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required ClassMembersBuilder membersBuilder,
      required Set<ClassMember>? getterOverrideDependencies}) {}

  @override
  void ensureSetterTypes(
      {required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required ClassMembersBuilder membersBuilder,
      required Set<ClassMember>? setterOverrideDependencies}) {}

  @override
  Iterable<Reference> getExportedGetterReferences(
      PropertyReferences references) {
    return [references.getterReference];
  }

  @override
  Iterable<Reference> getExportedSetterReferences(
      PropertyReferences references) {
    return hasSetter ? [references.setterReference] : const [];
  }
}

mixin FieldDeclarationMixin
    implements FieldDeclaration, Inferable, InferredTypeListener {
  Uri get fileUri;

  int get nameOffset;

  SourcePropertyBuilder get builder;

  @override
  bool get isConst;

  /// The [TypeBuilder] for the declared type of this field declaration.
  TypeBuilder get type;

  void setCovariantByClassInternal();

  abstract DartType fieldTypeInternal;

  @override
  void onInferredType(DartType type) {
    fieldType = type;
  }

  @override
  void inferTypes(ClassHierarchyBase hierarchy) {
    inferType(hierarchy);
  }

  @override
  DartType inferType(ClassHierarchyBase hierarchy) {
    if (fieldType is! InferredType) {
      // We have already inferred a type.
      return fieldType;
    }

    return builder.libraryBuilder.loader
        .withUriForCrashReporting(fileUri, nameOffset, () {
      InferredType implicitFieldType = fieldType as InferredType;
      DartType inferredType = implicitFieldType.computeType(hierarchy);
      if (fieldType is InferredType) {
        // `fieldType` may have changed if a circularity was detected when
        // [inferredType] was computed.
        type.registerInferredType(inferredType);

        // TODO(johnniwinther): Isn't this handled in the [fieldType] setter?
        IncludesTypeParametersNonCovariantly? needsCheckVisitor;
        DeclarationBuilder? declarationBuilder = builder.declarationBuilder;
        if (declarationBuilder is ClassBuilder) {
          Class enclosingClass = declarationBuilder.cls;
          if (enclosingClass.typeParameters.isNotEmpty) {
            needsCheckVisitor = new IncludesTypeParametersNonCovariantly(
                enclosingClass.typeParameters,
                // We are checking the field type as if it is the type of the
                // parameter of the implicit setter and this is a contravariant
                // position.
                initialVariance: Variance.contravariant);
          }
        }
        if (needsCheckVisitor != null) {
          if (fieldType.accept(needsCheckVisitor)) {
            setCovariantByClassInternal();
          }
        }
      }
      return fieldType;
    });
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType get fieldType => fieldTypeInternal;

  @override
  void set fieldType(DartType value) {
    fieldTypeInternal = value;
    DeclarationBuilder? declarationBuilder = builder.declarationBuilder;
    // TODO(johnniwinther): Should this be `hasSetter`?
    if (!isFinal && !isConst && declarationBuilder is ClassBuilder) {
      Class enclosingClass = declarationBuilder.cls;
      if (enclosingClass.typeParameters.isNotEmpty) {
        IncludesTypeParametersNonCovariantly needsCheckVisitor =
            new IncludesTypeParametersNonCovariantly(
                enclosingClass.typeParameters,
                // We are checking the field type as if it is the type of the
                // parameter of the implicit setter and this is a contravariant
                // position.
                initialVariance: Variance.contravariant);
        if (value.accept(needsCheckVisitor)) {
          setCovariantByClassInternal();
        }
      }
    }
  }
}

abstract class FieldFragmentDeclaration {
  bool get isStatic;

  void buildFieldInitializer(InferenceHelper helper, TypeInferrer typeInferrer,
      CoreTypes coreTypes, Expression? initializer);

  BodyBuilderContext createBodyBuilderContext();

  /// Registers that a `super` call has occurred in the initializer of this
  /// field.
  void registerSuperCall();
}
