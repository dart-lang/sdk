// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/metadata/expressions.dart' as shared;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/lowering_predicates.dart';
import '../base/constant_context.dart' show ConstantContext;
import '../base/modifiers.dart' show Modifiers;
import '../base/name_space.dart';
import '../base/problems.dart' show internalProblem;
import '../base/scope.dart' show LookupScope;
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/field_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/property_builder.dart';
import '../builder/type_builder.dart';
import '../codes/cfe_codes.dart' show messageInternalProblemAlreadyInitialized;
import '../kernel/body_builder.dart' show BodyBuilder;
import '../kernel/body_builder_context.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/members_builder.dart';
import '../kernel/implicit_field_type.dart';
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/late_lowering.dart' as late_lowering;
import '../kernel/macro/metadata.dart';
import '../kernel/member_covariance.dart';
import '../kernel/type_algorithms.dart';
import '../source/name_scheme.dart';
import '../source/source_extension_builder.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../type_inference/type_inference_engine.dart'
    show IncludesTypeParametersNonCovariantly;
import 'source_class_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_member_builder.dart';

class SourceFieldBuilder extends SourceMemberBuilderImpl
    implements FieldBuilder, InferredTypeListener, Inferable, PropertyBuilder {
  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final String name;

  final MemberName _memberName;

  final Modifiers modifiers;

  late FieldEncoding _fieldEncoding;

  final List<MetadataBuilder>? metadata;

  final TypeBuilder type;

  Token? _constInitializerToken;

  shared.Expression? _initializerExpression;

  /// Whether the body of this field has been built.
  ///
  /// Constant fields have their initializer built in the outline so we avoid
  /// building them twice as part of the non-outline build.
  bool hasBodyBeenBuilt = false;

  // TODO(johnniwinther): [parent] is not trust-worthy for determining
  //  properties since it is changed after the creation of the builder. For now
  //  we require it has an argument here. A follow-up should clean up the
  //  misuse of parent.
  @override
  final bool isTopLevel;

  final bool isPrimaryConstructorField;

  @override
  final bool isSynthesized;

  /// If `true`, this field builder is for the field corresponding to an enum
  /// element.
  @override
  final bool isEnumElement;

  @override
  final DeclarationBuilder? declarationBuilder;

  final int nameOffset;

  @override
  final Uri fileUri;

  SourceFieldBuilder(
      {required this.metadata,
      required this.type,
      required this.name,
      required this.modifiers,
      required this.isTopLevel,
      required this.isPrimaryConstructorField,
      required this.libraryBuilder,
      required this.declarationBuilder,
      required this.fileUri,
      required this.nameOffset,
      required int endOffset,
      required NameScheme nameScheme,
      Reference? fieldReference,
      Reference? fieldGetterReference,
      Reference? fieldSetterReference,
      Reference? lateIsSetFieldReference,
      Reference? lateIsSetGetterReference,
      Reference? lateIsSetSetterReference,
      Reference? lateGetterReference,
      Reference? lateSetterReference,
      Token? initializerToken,
      Token? constInitializerToken,
      this.isSynthesized = false,
      this.isEnumElement = false})
      : _constInitializerToken = constInitializerToken,
        _memberName = nameScheme.getDeclaredName(name) {
    type.registerInferredTypeListener(this);

    bool isInstanceMember = nameScheme.isInstanceMember;

    // If in mixed mode, late lowerings cannot use `null` as a sentinel on
    // non-nullable fields since they can be assigned from legacy code.
    late_lowering.IsSetStrategy isSetStrategy =
        late_lowering.computeIsSetStrategy(libraryBuilder);
    if (isAbstract || isExternal) {
      // Coverage-ignore-block(suite): Not run.
      assert(fieldReference == null);
      assert(lateIsSetFieldReference == null);
      assert(lateIsSetGetterReference == null);
      assert(lateIsSetSetterReference == null);
      assert(lateGetterReference == null);
      assert(lateSetterReference == null);
      assert(!isEnumElement, "Unexpected abstract/external enum element");
      _fieldEncoding = new AbstractOrExternalFieldEncoding(
          this,
          name,
          nameScheme,
          fileUri,
          nameOffset,
          endOffset,
          fieldGetterReference,
          fieldSetterReference,
          isAbstract: isAbstract,
          isExternal: isExternal,
          isFinal: isFinal,
          isCovariantByDeclaration: isCovariantByDeclaration);
    } else if (nameScheme.isExtensionTypeMember &&
        // Coverage-ignore(suite): Not run.
        nameScheme.isInstanceMember) {
      // Coverage-ignore-block(suite): Not run.
      assert(fieldReference == null);
      assert(fieldSetterReference == null);
      assert(lateIsSetFieldReference == null);
      assert(lateIsSetGetterReference == null);
      assert(lateIsSetSetterReference == null);
      assert(lateGetterReference == null);
      assert(lateSetterReference == null);
      if (isPrimaryConstructorField) {
        _fieldEncoding = new RepresentationFieldEncoding(this, name, nameScheme,
            fileUri, nameOffset, endOffset, fieldGetterReference);
      } else {
        // Field on a extension type. Encode as abstract.
        // TODO(johnniwinther): Should we have an erroneous flag on such
        // members?
        _fieldEncoding = new AbstractOrExternalFieldEncoding(
            this,
            name,
            nameScheme,
            fileUri,
            nameOffset,
            endOffset,
            fieldGetterReference,
            fieldSetterReference,
            isAbstract: true,
            isExternal: false,
            isFinal: isFinal,
            isCovariantByDeclaration: isCovariantByDeclaration,
            isForcedExtension: true);
      }
    } else if (isLate &&
        // Coverage-ignore(suite): Not run.
        libraryBuilder.loader.target.backendTarget.isLateFieldLoweringEnabled(
            hasInitializer: hasInitializer,
            isFinal: isFinal,
            isStatic: !isInstanceMember)) {
      // Coverage-ignore-block(suite): Not run.
      assert(!isEnumElement, "Unexpected late enum element");
      if (hasInitializer) {
        if (isFinal) {
          _fieldEncoding = new LateFinalFieldWithInitializerEncoding(
              name: name,
              nameScheme: nameScheme,
              fileUri: fileUri,
              nameOffset: nameOffset,
              endOffset: endOffset,
              fieldReference: fieldReference,
              fieldGetterReference: fieldGetterReference,
              fieldSetterReference: fieldSetterReference,
              lateIsSetFieldReference: lateIsSetFieldReference,
              lateIsSetGetterReference: lateIsSetGetterReference,
              lateIsSetSetterReference: lateIsSetSetterReference,
              lateGetterReference: lateGetterReference,
              lateSetterReference: lateSetterReference,
              isCovariantByDeclaration: isCovariantByDeclaration,
              isSetStrategy: isSetStrategy);
        } else {
          _fieldEncoding = new LateFieldWithInitializerEncoding(
              name: name,
              nameScheme: nameScheme,
              fileUri: fileUri,
              nameOffset: nameOffset,
              endOffset: endOffset,
              fieldReference: fieldReference,
              fieldGetterReference: fieldGetterReference,
              fieldSetterReference: fieldSetterReference,
              lateIsSetFieldReference: lateIsSetFieldReference,
              lateIsSetGetterReference: lateIsSetGetterReference,
              lateIsSetSetterReference: lateIsSetSetterReference,
              lateGetterReference: lateGetterReference,
              lateSetterReference: lateSetterReference,
              isCovariantByDeclaration: isCovariantByDeclaration,
              isSetStrategy: isSetStrategy);
        }
      } else {
        if (isFinal) {
          _fieldEncoding = new LateFinalFieldWithoutInitializerEncoding(
              name: name,
              nameScheme: nameScheme,
              fileUri: fileUri,
              nameOffset: nameOffset,
              endOffset: endOffset,
              fieldReference: fieldReference,
              fieldGetterReference: fieldGetterReference,
              fieldSetterReference: fieldSetterReference,
              lateIsSetFieldReference: lateIsSetFieldReference,
              lateIsSetGetterReference: lateIsSetGetterReference,
              lateIsSetSetterReference: lateIsSetSetterReference,
              lateGetterReference: lateGetterReference,
              lateSetterReference: lateSetterReference,
              isCovariantByDeclaration: isCovariantByDeclaration,
              isSetStrategy: isSetStrategy);
        } else {
          _fieldEncoding = new LateFieldWithoutInitializerEncoding(
              name: name,
              nameScheme: nameScheme,
              fileUri: fileUri,
              nameOffset: nameOffset,
              endOffset: endOffset,
              fieldReference: fieldReference,
              fieldGetterReference: fieldGetterReference,
              fieldSetterReference: fieldSetterReference,
              lateIsSetFieldReference: lateIsSetFieldReference,
              lateIsSetGetterReference: lateIsSetGetterReference,
              lateIsSetSetterReference: lateIsSetSetterReference,
              lateGetterReference: lateGetterReference,
              lateSetterReference: lateSetterReference,
              isCovariantByDeclaration: isCovariantByDeclaration,
              isSetStrategy: isSetStrategy);
        }
      }
    } else if (libraryBuilder
            .loader.target.backendTarget.useStaticFieldLowering &&
        !isInstanceMember &&
        !isConst &&
        // Coverage-ignore(suite): Not run.
        hasInitializer) {
      // Coverage-ignore-block(suite): Not run.
      assert(!isEnumElement, "Unexpected non-const enum element");
      if (isFinal) {
        _fieldEncoding = new LateFinalFieldWithInitializerEncoding(
            name: name,
            nameScheme: nameScheme,
            fileUri: fileUri,
            nameOffset: nameOffset,
            endOffset: endOffset,
            fieldReference: fieldReference,
            fieldGetterReference: fieldGetterReference,
            fieldSetterReference: fieldSetterReference,
            lateIsSetFieldReference: lateIsSetFieldReference,
            lateIsSetGetterReference: lateIsSetGetterReference,
            lateIsSetSetterReference: lateIsSetSetterReference,
            lateGetterReference: lateGetterReference,
            lateSetterReference: lateSetterReference,
            isCovariantByDeclaration: isCovariantByDeclaration,
            isSetStrategy: isSetStrategy);
      } else {
        _fieldEncoding = new LateFieldWithInitializerEncoding(
            name: name,
            nameScheme: nameScheme,
            fileUri: fileUri,
            nameOffset: nameOffset,
            endOffset: endOffset,
            fieldReference: fieldReference,
            fieldGetterReference: fieldGetterReference,
            fieldSetterReference: fieldSetterReference,
            lateIsSetFieldReference: lateIsSetFieldReference,
            lateIsSetGetterReference: lateIsSetGetterReference,
            lateIsSetSetterReference: lateIsSetSetterReference,
            lateGetterReference: lateGetterReference,
            lateSetterReference: lateSetterReference,
            isCovariantByDeclaration: isCovariantByDeclaration,
            isSetStrategy: isSetStrategy);
      }
    } else {
      assert(lateIsSetFieldReference == null);
      assert(lateIsSetGetterReference == null);
      assert(lateIsSetSetterReference == null);
      assert(lateGetterReference == null);
      assert(lateSetterReference == null);
      _fieldEncoding = new RegularFieldEncoding(
          name: name,
          nameScheme: nameScheme,
          fileUri: fileUri,
          nameOffset: nameOffset,
          endOffset: endOffset,
          isFinal: isFinal,
          isConst: isConst,
          isLate: isLate,
          hasInitializer: hasInitializer,
          fieldReference: fieldReference,
          getterReference: fieldGetterReference,
          setterReference: fieldSetterReference,
          isEnumElement: isEnumElement);
    }

    if (type is InferableTypeBuilder) {
      // Coverage-ignore-block(suite): Not run.
      if (!hasInitializer && isStatic) {
        // A static field without type and initializer will always be inferred
        // to have type `dynamic`.
        type.registerInferredType(const DynamicType());
      } else {
        // A field with no type and initializer or an instance field without
        // type and initializer need to have the type inferred.
        _fieldEncoding.type =
            new InferredType.fromFieldInitializer(this, initializerToken);
        type.registerInferable(this);
      }
    }
  }

  @override
  int get fileOffset => nameOffset;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => metadata;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAugmentation => modifiers.isAugment;

  @override
  bool get isExternal => modifiers.isExternal;

  @override
  bool get isAbstract => modifiers.isAbstract;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExtensionTypeDeclaredInstanceField =>
      isExtensionTypeInstanceMember && !isPrimaryConstructorField;

  @override
  bool get isConst => modifiers.isConst;

  @override
  bool get isFinal => modifiers.isFinal;

  @override
  bool get isStatic => modifiers.isStatic;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAugment => modifiers.isAugment;

  @override
  Builder get parent =>
      declarationBuilder ?? // Coverage-ignore(suite): Not run.
      libraryBuilder;

  @override
  Name get memberName => _memberName.name;

  bool _typeEnsured = false;
  Set<ClassMember>? _overrideDependencies;

  // Coverage-ignore(suite): Not run.
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    assert(
        overriddenMembers.every((overriddenMember) =>
            overriddenMember.declarationBuilder != classBuilder),
        "Unexpected override dependencies for $this: $overriddenMembers");
    _overrideDependencies ??= {};
    _overrideDependencies!.addAll(overriddenMembers);
  }

  void _ensureType(ClassMembersBuilder membersBuilder) {
    if (_typeEnsured) return;
    if (_overrideDependencies != null) {
      // Coverage-ignore-block(suite): Not run.
      membersBuilder.inferFieldType(declarationBuilder as SourceClassBuilder,
          type, _overrideDependencies!,
          name: fullNameForErrors,
          fileUri: fileUri,
          nameOffset: nameOffset,
          nameLength: fullNameForErrors.length,
          isAssignable: isAssignable);
      _overrideDependencies = null;
    } else {
      type.build(libraryBuilder, TypeUse.fieldType,
          hierarchy: membersBuilder.hierarchyBuilder);
    }
    _typeEnsured = true;
  }

  @override
  bool get isField => true;

  @override
  bool get isLate => modifiers.isLate;

  bool get isCovariantByDeclaration => modifiers.isCovariant;

  @override
  bool get hasInitializer => modifiers.hasInitializer;

  /// Builds the body of this field using [initializer] as the initializer
  /// expression.
  void buildBody(CoreTypes coreTypes, Expression? initializer) {
    assert(!hasBodyBeenBuilt, "Body has already been built for $this.");
    hasBodyBeenBuilt = true;
    if (!hasInitializer &&
        initializer != null &&
        // Coverage-ignore(suite): Not run.
        initializer is! NullLiteral &&
        // Coverage-ignore(suite): Not run.
        !isConst &&
        // Coverage-ignore(suite): Not run.
        !isFinal) {
      internalProblem(
          messageInternalProblemAlreadyInitialized, fileOffset, fileUri);
    }
    _fieldEncoding.createBodies(coreTypes, initializer);
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<Initializer> buildInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    return _fieldEncoding.createInitializer(fileOffset, value,
        isSynthetic: isSynthetic);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void buildImplicitDefaultValue() {
    _fieldEncoding.buildImplicitDefaultValue();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Initializer buildImplicitInitializer() {
    return _fieldEncoding.buildImplicitInitializer();
  }

  @override
  // Coverage-ignore(suite): Not run.
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    return _fieldEncoding.buildErroneousInitializer(effect, value,
        fileOffset: fileOffset);
  }

  @override
  bool get isAssignable {
    if (isConst) return false;
    // Coverage-ignore(suite): Not run.
    if (isFinal) {
      if (isLate) {
        return !hasInitializer;
      }
      return false;
    }
    return true;
  }

  @override
  Field get field => _fieldEncoding.field;

  @override
  Member get readTarget => _fieldEncoding.readTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _fieldEncoding.readTargetReference;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget {
    return isAssignable ? _fieldEncoding.writeTarget : null;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => _fieldEncoding.writeTargetReference;

  @override
  Member get invokeTarget => readTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _fieldEncoding.readTargetReference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences =>
      _fieldEncoding.exportedReferenceMembers;

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _build();
    _fieldEncoding.registerMembers(libraryBuilder, this, f);
  }

  /// Builds the core AST structures for this field as needed for the outline.
  void _build() {
    if (type is! InferableTypeBuilder) {
      fieldType = type.build(libraryBuilder, TypeUse.fieldType);
    }
    _fieldEncoding.build(libraryBuilder, this);
  }

  BodyBuilderContext createBodyBuilderContext() {
    return new FieldBodyBuilderContext(this, _fieldEncoding.builtMember);
  }

  @override
  Iterable<Annotatable> get annotatables => _fieldEncoding.annotatables;

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    for (Annotatable annotatable in annotatables) {
      MetadataBuilder.buildAnnotations(
          annotatable,
          metadata,
          createBodyBuilderContext(),
          libraryBuilder,
          fileUri,
          declarationBuilder?.scope ?? // Coverage-ignore(suite): Not run.
              libraryBuilder.scope);
    }

    // For modular compilation we need to include initializers of all const
    // fields and all non-static final fields in classes with const constructors
    // into the outline.
    if ((isConst ||
            // Coverage-ignore(suite): Not run.
            (isFinal &&
                !isStatic &&
                isClassMember &&
                classBuilder!.declaresConstConstructor)) &&
        _constInitializerToken != null) {
      // Coverage-ignore-block(suite): Not run.
      Token initializerToken = _constInitializerToken!;
      LookupScope scope = declarationBuilder?.scope ?? libraryBuilder.scope;
      BodyBuilder bodyBuilder = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(
              libraryBuilder, createBodyBuilderContext(), scope, fileUri);
      bodyBuilder.constantContext =
          isConst ? ConstantContext.inferred : ConstantContext.required;
      Expression initializer = bodyBuilder.typeInferrer
          .inferFieldInitializer(bodyBuilder, fieldType,
              bodyBuilder.parseFieldInitializer(initializerToken))
          .expression;
      buildBody(classHierarchy.coreTypes, initializer);
      bodyBuilder.performBacklogComputations();
      if (computeSharedExpressionForTesting) {
        _initializerExpression = parseFieldInitializer(libraryBuilder.loader,
            initializerToken, libraryBuilder.importUri, fileUri, scope);
      }
    }
    _constInitializerToken = null;
  }

  // Coverage-ignore(suite): Not run.
  shared.Expression? get initializerExpression => _initializerExpression;

  // Coverage-ignore(suite): Not run.
  bool get hasOutlineExpressionsBuilt => _constInitializerToken == null;

  @override
  DartType get fieldType => _fieldEncoding.type;

  @override
  void set fieldType(DartType value) {
    _fieldEncoding.type = value;
    if (!isFinal &&
        !isConst &&
        // Coverage-ignore(suite): Not run.
        parent is ClassBuilder) {
      // Coverage-ignore-block(suite): Not run.
      Class enclosingClass = classBuilder!.cls;
      if (enclosingClass.typeParameters.isNotEmpty) {
        IncludesTypeParametersNonCovariantly needsCheckVisitor =
            new IncludesTypeParametersNonCovariantly(
                enclosingClass.typeParameters,
                // We are checking the field type as if it is the type of the
                // parameter of the implicit setter and this is a contravariant
                // position.
                initialVariance: Variance.contravariant);
        if (value.accept(needsCheckVisitor)) {
          _fieldEncoding.setGenericCovariantImpl();
        }
      }
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void inferTypes(ClassHierarchyBase hierarchy) {
    inferType(hierarchy);
  }

  @override
  // Coverage-ignore(suite): Not run.
  DartType inferType(ClassHierarchyBase hierarchy) {
    if (fieldType is! InferredType) {
      // We have already inferred a type.
      return fieldType;
    }

    return libraryBuilder.loader.withUriForCrashReporting(fileUri, fileOffset,
        () {
      InferredType implicitFieldType = fieldType as InferredType;
      DartType inferredType = implicitFieldType.computeType(hierarchy);
      if (fieldType is InferredType) {
        // `fieldType` may have changed if a circularity was detected when
        // [inferredType] was computed.
        type.registerInferredType(inferredType);

        IncludesTypeParametersNonCovariantly? needsCheckVisitor;
        if (parent is ClassBuilder) {
          Class enclosingClass = classBuilder!.cls;
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
            _fieldEncoding.setGenericCovariantImpl();
          }
        }
      }
      return fieldType;
    });
  }

  @override
  // Coverage-ignore(suite): Not run.
  void onInferredType(DartType type) {
    fieldType = type;
  }

  // Coverage-ignore(suite): Not run.
  DartType get builtType => fieldType;

  List<ClassMember>? _localMembers;
  List<ClassMember>? _localSetters;

  @override
  List<ClassMember> get localMembers =>
      _localMembers ??= _fieldEncoding.getLocalMembers(this);

  @override
  List<ClassMember> get localSetters =>
      _localSetters ??= _fieldEncoding.getLocalSetters(this);

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    TypeBuilder? fieldType = type;
    if (fieldType is! OmittedTypeBuilder) {
      context.reportInboundReferenceIssuesForType(fieldType);
      context.recursivelyReportGenericFunctionTypesAsBoundsForType(fieldType);
    }
    return 0;
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    sourceClassBuilder.checkVarianceInField(typeEnvironment,
        fieldType: fieldType,
        isInstanceMember: isClassInstanceMember,
        hasSetter: isAssignable,
        isCovariantByDeclaration: isCovariantByDeclaration,
        fileUri: fileUri,
        fileOffset: fileOffset);
  }

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    library.checkTypesInField(typeEnvironment,
        isInstanceMember: isDeclarationInstanceMember,
        isLate: isLate,
        isExternal: isExternal,
        hasInitializer: hasInitializer,
        fieldType: fieldType,
        name: name,
        nameLength: name.length,
        nameOffset: fileOffset,
        fileUri: fileUri);
  }

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    return 0;
  }
}

/// Strategy pattern for creating different encodings of a declared field.
///
/// This is used to provide lowerings for late fields using synthesized getters
/// and setters.
abstract class FieldEncoding {
  /// The type of the declared field.
  abstract DartType type;

  /// Creates the bodies needed for the field encoding using [initializer] as
  /// the declared initializer expression.
  ///
  /// This method is not called for fields in outlines unless their are constant
  /// or part of a const constructor.
  void createBodies(CoreTypes coreTypes, Expression? initializer);

  List<Initializer> createInitializer(int fileOffset, Expression value,
      {required bool isSynthetic});

  /// Creates the AST node for this field as the default initializer.
  void buildImplicitDefaultValue();

  /// Create the [Initializer] for the implicit initialization of this field
  /// in a constructor.
  Initializer buildImplicitInitializer();

  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset});

  /// Registers that the (implicit) setter associated with this field needs to
  /// contain a runtime type check to deal with generic covariance.
  void setGenericCovariantImpl();

  /// Returns the field that holds the field value at runtime.
  Field get field;

  /// The [Member] built during [SourceFieldBuilder.buildOutlineExpressions].
  Member get builtMember;

  /// Returns the members that holds the field annotations.
  Iterable<Annotatable> get annotatables;

  /// Returns the member used to read the field value.
  Member get readTarget;

  /// Returns the reference used to read the field value.
  Reference get readTargetReference;

  /// Returns the member used to write to the field.
  Member? get writeTarget;

  /// Returns the reference used to write to the field.
  Reference? get writeTargetReference;

  /// Returns the references to the generated members that are visible through
  /// exports.
  ///
  /// This is the getter reference, and, if available, the setter reference.
  Iterable<Reference> get exportedReferenceMembers;

  /// Creates the members necessary for this field encoding.
  ///
  /// This method is called for both outline and full compilation so the created
  /// members should be without body. The member bodies are created through
  /// [createBodies].
  void build(
      SourceLibraryBuilder libraryBuilder, SourceFieldBuilder fieldBuilder);

  /// Calls [f] for each member needed for this field encoding.
  void registerMembers(SourceLibraryBuilder library,
      SourceFieldBuilder fieldBuilder, BuildNodesCallback f);

  /// Returns a list of the field, getters and methods created by this field
  /// encoding.
  List<ClassMember> getLocalMembers(SourceFieldBuilder fieldBuilder);

  /// Returns a list of the setters created by this field encoding.
  List<ClassMember> getLocalSetters(SourceFieldBuilder fieldBuilder);
}

class RegularFieldEncoding implements FieldEncoding {
  late final Field _field;

  RegularFieldEncoding(
      {required String name,
      required NameScheme nameScheme,
      required Uri fileUri,
      required int nameOffset,
      required int endOffset,
      required bool isFinal,
      required bool isConst,
      required bool isLate,
      required bool hasInitializer,
      required Reference? fieldReference,
      required Reference? getterReference,
      required Reference? setterReference,
      required bool isEnumElement}) {
    bool isImmutable =
        isLate ? (isFinal && hasInitializer) : (isFinal || isConst);
    _field = isImmutable
        ? new Field.immutable(dummyName,
            isFinal: isFinal,
            isConst: isConst,
            isLate: isLate,
            fileUri: fileUri,
            fieldReference: fieldReference,
            getterReference: getterReference,
            isEnumElement: isEnumElement)
        :
        // Coverage-ignore(suite): Not run.
        new Field.mutable(dummyName,
            isFinal: isFinal,
            isLate: isLate,
            fileUri: fileUri,
            fieldReference: fieldReference,
            getterReference: getterReference,
            setterReference: setterReference);
    nameScheme
        .getFieldMemberName(FieldNameType.Field, name, isSynthesized: false)
        .attachMember(_field);
    _field
      ..fileOffset = nameOffset
      ..fileEndOffset = endOffset;
  }

  @override
  DartType get type => _field.type;

  @override
  void set type(DartType value) {
    _field.type = value;
  }

  @override
  void createBodies(CoreTypes coreTypes, Expression? initializer) {
    if (initializer != null) {
      _field.initializer = initializer..parent = _field;
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<Initializer> createInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    return <Initializer>[
      new FieldInitializer(_field, value)
        ..fileOffset = fileOffset
        ..isSynthetic = isSynthetic
    ];
  }

  @override
  void build(
      SourceLibraryBuilder libraryBuilder, SourceFieldBuilder fieldBuilder) {
    _field..isCovariantByDeclaration = fieldBuilder.isCovariantByDeclaration;
    if (fieldBuilder.isExtensionMember) {
      // Coverage-ignore-block(suite): Not run.
      _field
        ..isStatic = true
        ..isExtensionMember = true;
    } else if (fieldBuilder.isExtensionTypeMember) {
      // Coverage-ignore-block(suite): Not run.
      _field
        ..isStatic = fieldBuilder.isStatic
        ..isExtensionTypeMember = true;
    } else {
      bool isInstanceMember = !fieldBuilder.isStatic &&
          // Coverage-ignore(suite): Not run.
          !fieldBuilder.isTopLevel;
      _field
        ..isStatic = !isInstanceMember
        ..isExtensionMember = false;
    }
    _field.isLate = fieldBuilder.isLate;
  }

  @override
  void registerMembers(SourceLibraryBuilder library,
      SourceFieldBuilder fieldBuilder, BuildNodesCallback f) {
    f(
        member: _field,
        kind:
            fieldBuilder.isExtensionMember || fieldBuilder.isExtensionTypeMember
                ? BuiltMemberKind.ExtensionField
                : BuiltMemberKind.Field);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void setGenericCovariantImpl() {
    if (_field.hasSetter) {
      _field.isCovariantByClass = true;
    }
  }

  @override
  Field get field => _field;

  @override
  Member get builtMember => _field;

  @override
  Iterable<Annotatable> get annotatables => [_field];

  @override
  Member get readTarget => _field;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _field.getterReference;

  @override
  // Coverage-ignore(suite): Not run.
  Member get writeTarget => _field;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => _field.setterReference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedReferenceMembers =>
      [_field.getterReference, if (_field.hasSetter) _field.setterReference!];

  @override
  List<ClassMember> getLocalMembers(SourceFieldBuilder fieldBuilder) =>
      <ClassMember>[
        new SourceFieldMember(fieldBuilder, ClassMemberKind.Getter)
      ];

  @override
  List<ClassMember> getLocalSetters(SourceFieldBuilder fieldBuilder) =>
      fieldBuilder.isAssignable
          ?
          // Coverage-ignore(suite): Not run.
          <ClassMember>[
              new SourceFieldMember(fieldBuilder, ClassMemberKind.Setter)
            ]
          : const <ClassMember>[];

  @override
  // Coverage-ignore(suite): Not run.
  void buildImplicitDefaultValue() {
    _field.initializer = new NullLiteral()..parent = _field;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Initializer buildImplicitInitializer() {
    return new FieldInitializer(_field, new NullLiteral())..isSynthetic = true;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    return new ShadowInvalidFieldInitializer(type, value, effect)
      ..fileOffset = fileOffset;
  }
}

class SourceFieldMember extends BuilderClassMember {
  @override
  final SourceFieldBuilder memberBuilder;

  Covariance? _covariance;

  @override
  final ClassMemberKind memberKind;

  SourceFieldMember(this.memberBuilder, this.memberKind);

  @override
  // Coverage-ignore(suite): Not run.
  void inferType(ClassMembersBuilder membersBuilder) {
    memberBuilder._ensureType(membersBuilder);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    memberBuilder.registerOverrideDependency(overriddenMembers);
  }

  @override
  Member getMember(ClassMembersBuilder membersBuilder) {
    memberBuilder._ensureType(membersBuilder);
    return memberBuilder.field;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Member? getTearOff(ClassMembersBuilder membersBuilder) {
    // Ensure field type is computed.
    getMember(membersBuilder);
    return null;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Covariance getCovariance(ClassMembersBuilder membersBuilder) {
    return _covariance ??= forSetter
        ? new Covariance.fromMember(getMember(membersBuilder),
            forSetter: forSetter)
        : const Covariance.empty();
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSourceDeclaration => true;

  @override
  bool get isSynthesized => memberBuilder.isSynthesized;

  @override
  bool isSameDeclaration(ClassMember other) {
    return other is SourceFieldMember &&
        // Coverage-ignore(suite): Not run.
        memberBuilder == other.memberBuilder;
  }
}

// Coverage-ignore(suite): Not run.
abstract class AbstractLateFieldEncoding implements FieldEncoding {
  final String name;
  final int fileOffset;
  final int fileEndOffset;
  DartType? _type;
  late final Field _field;
  Field? _lateIsSetField;
  late Procedure _lateGetter;
  Procedure? _lateSetter;

  // If `true`, an isSet field is used even when the type of the field is
  // not potentially nullable.
  //
  // This is used to force use isSet fields in mixed mode encoding since
  // we cannot trust non-nullable fields to be initialized with non-null values.
  final late_lowering.IsSetStrategy _isSetStrategy;
  late_lowering.IsSetEncoding? _isSetEncoding;

  // If `true`, the is-set field was register before the type was known to be
  // nullable or non-nullable. In this case we do not try to remove it from
  // the generated AST to avoid inconsistency between the class hierarchy used
  // during and after inference.
  //
  // This is also used to force use isSet fields in mixed mode encoding since
  // we cannot trust non-nullable fields to be initialized with non-null values.
  bool _forceIncludeIsSetField;

  AbstractLateFieldEncoding(
      {required this.name,
      required NameScheme nameScheme,
      required Uri fileUri,
      required int nameOffset,
      required int endOffset,
      required Reference? fieldReference,
      required Reference? fieldGetterReference,
      required Reference? fieldSetterReference,
      required Reference? lateIsSetFieldReference,
      required Reference? lateIsSetGetterReference,
      required Reference? lateIsSetSetterReference,
      required Reference? lateGetterReference,
      required Reference? lateSetterReference,
      required bool isCovariantByDeclaration,
      required late_lowering.IsSetStrategy isSetStrategy})
      : fileOffset = nameOffset,
        fileEndOffset = endOffset,
        _isSetStrategy = isSetStrategy,
        _forceIncludeIsSetField =
            isSetStrategy == late_lowering.IsSetStrategy.forceUseIsSetField {
    _field = new Field.mutable(dummyName,
        fileUri: fileUri,
        fieldReference: fieldReference,
        getterReference: fieldGetterReference,
        setterReference: fieldSetterReference)
      ..fileOffset = nameOffset
      ..fileEndOffset = endOffset
      ..isInternalImplementation = true;
    nameScheme
        .getFieldMemberName(FieldNameType.Field, name, isSynthesized: true)
        .attachMember(_field);
    switch (_isSetStrategy) {
      case late_lowering.IsSetStrategy.useSentinelOrNull:
      case late_lowering.IsSetStrategy.forceUseSentinel:
        // [_lateIsSetField] is never needed.
        break;
      case late_lowering.IsSetStrategy.forceUseIsSetField:
      case late_lowering.IsSetStrategy.useIsSetFieldOrNull:
        _lateIsSetField = new Field.mutable(dummyName,
            fileUri: fileUri,
            fieldReference: lateIsSetFieldReference,
            getterReference: lateIsSetGetterReference,
            setterReference: lateIsSetSetterReference)
          ..fileOffset = nameOffset
          ..fileEndOffset = endOffset
          ..isInternalImplementation = true;
        nameScheme
            .getFieldMemberName(FieldNameType.IsSetField, name,
                isSynthesized: true)
            .attachMember(_lateIsSetField!);
        break;
    }
    _lateGetter = new Procedure(
        dummyName,
        ProcedureKind.Getter,
        new FunctionNode(null)
          ..fileOffset = nameOffset
          ..fileEndOffset = endOffset,
        fileUri: fileUri,
        reference: lateGetterReference)
      ..fileOffset = nameOffset
      ..fileEndOffset = endOffset;
    nameScheme
        .getFieldMemberName(FieldNameType.Getter, name, isSynthesized: true)
        .attachMember(_lateGetter);
    _lateSetter = _createSetter(fileUri, nameOffset, lateSetterReference,
        isCovariantByDeclaration: isCovariantByDeclaration);
    if (_lateSetter != null) {
      nameScheme
          .getFieldMemberName(FieldNameType.Setter, name, isSynthesized: true)
          .attachMember(_lateSetter!);
    }
  }

  late_lowering.IsSetEncoding get isSetEncoding {
    assert(_type != null, "Type has not been computed for field $name.");
    return _isSetEncoding ??=
        late_lowering.computeIsSetEncoding(_type!, _isSetStrategy);
  }

  @override
  void createBodies(CoreTypes coreTypes, Expression? initializer) {
    assert(_type != null, "Type has not been computed for field $name.");
    if (isSetEncoding == late_lowering.IsSetEncoding.useSentinel) {
      _field.initializer = new StaticInvocation(coreTypes.createSentinelMethod,
          new Arguments([], types: [_type!])..fileOffset = fileOffset)
        ..fileOffset = fileOffset
        ..parent = _field;
    } else {
      _field.initializer = new NullLiteral()
        ..fileOffset = fileOffset
        ..parent = _field;
    }
    if (_lateIsSetField != null) {
      _lateIsSetField!.initializer = new BoolLiteral(false)
        ..fileOffset = fileOffset
        ..parent = _lateIsSetField;
    }
    _lateGetter.function.body = _createGetterBody(coreTypes, name, initializer)
      ..parent = _lateGetter.function;
    // The initializer is copied from [_field] to [_lateGetter] so we copy the
    // transformer flags to reflect whether the getter contains super calls.
    _lateGetter.transformerFlags = _field.transformerFlags;

    if (_lateSetter != null) {
      _lateSetter!.function.body = _createSetterBody(
          coreTypes, name, _lateSetter!.function.positionalParameters.first)
        ..parent = _lateSetter!.function;
    }
  }

  @override
  List<Initializer> createInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    List<Initializer> initializers = <Initializer>[];
    if (_lateIsSetField != null) {
      initializers.add(new FieldInitializer(
          _lateIsSetField!, new BoolLiteral(true)..fileOffset = fileOffset)
        ..fileOffset = fileOffset
        ..isSynthetic = isSynthetic);
    }
    initializers.add(new FieldInitializer(_field, value)
      ..fileOffset = fileOffset
      ..isSynthetic = isSynthetic);
    return initializers;
  }

  /// Creates an [Expression] that reads [_field].
  ///
  /// If [needsPromotion] is `true`, the field will be read through a `let`
  /// expression that promotes the expression to [_type]. This is needed for a
  /// sound encoding of fields with type parameter type of undetermined
  /// nullability.
  Expression _createFieldRead({bool needsPromotion = false}) {
    assert(_type != null, "Type has not been computed for field $name.");
    if (needsPromotion) {
      VariableDeclaration variable = new VariableDeclaration.forValue(
          _createFieldGet(_field),
          type: _type!.withDeclaredNullability(Nullability.nullable))
        ..fileOffset = fileOffset;
      return new Let(
          variable, new VariableGet(variable, _type)..fileOffset = fileOffset);
    } else {
      return _createFieldGet(_field);
    }
  }

  /// Creates an [Expression] that reads [field].
  Expression _createFieldGet(Field field) {
    if (field.isStatic) {
      return new StaticGet(field)..fileOffset = fileOffset;
    } else {
      // No substitution needed for the result type, since any type parameters
      // in there are also in scope at the access site.
      return new InstanceGet(InstanceAccessKind.Instance,
          new ThisExpression()..fileOffset = fileOffset, field.name,
          interfaceTarget: field, resultType: field.type)
        ..fileOffset = fileOffset;
    }
  }

  /// Creates an [Expression] that writes [value] to [field].
  Expression _createFieldSet(Field field, Expression value) {
    if (field.isStatic) {
      return new StaticSet(field, value)..fileOffset = fileOffset;
    } else {
      return new InstanceSet(InstanceAccessKind.Instance,
          new ThisExpression()..fileOffset = fileOffset, field.name, value,
          interfaceTarget: field)
        ..fileOffset = fileOffset;
    }
  }

  Statement _createGetterBody(
      CoreTypes coreTypes, String name, Expression? initializer);

  Procedure? _createSetter(Uri fileUri, int charOffset, Reference? reference,
      {required bool isCovariantByDeclaration}) {
    VariableDeclaration parameter = new VariableDeclaration("${name}#param")
      ..isCovariantByDeclaration = isCovariantByDeclaration
      ..fileOffset = fileOffset;
    return new Procedure(
        dummyName,
        ProcedureKind.Setter,
        new FunctionNode(null,
            positionalParameters: [parameter], returnType: const VoidType())
          ..fileOffset = charOffset
          ..fileEndOffset = fileEndOffset,
        fileUri: fileUri,
        reference: reference)
      ..fileOffset = charOffset
      ..fileEndOffset = fileEndOffset;
  }

  Statement _createSetterBody(
      CoreTypes coreTypes, String name, VariableDeclaration parameter);

  @override
  DartType get type {
    assert(_type != null, "Type has not been computed for field $name.");
    return _type!;
  }

  @override
  void set type(DartType value) {
    assert(_type == null || _type is InferredType,
        "Type has already been computed for field $name.");
    _type = value;
    if (value is! InferredType) {
      _field.type = value.withDeclaredNullability(Nullability.nullable);
      _lateGetter.function.returnType = value;
      if (_lateSetter != null) {
        _lateSetter!.function.positionalParameters.single.type = value;
      }
      if (!_type!.isPotentiallyNullable && !_forceIncludeIsSetField) {
        // We only need the is-set field if the field is potentially nullable.
        //  Otherwise we use `null` to signal that the field is uninitialized.
        _lateIsSetField = null;
      }
    }
  }

  @override
  void setGenericCovariantImpl() {
    if (_field.hasSetter) {
      _field.isCovariantByClass = true;
    }
    _lateSetter?.function.positionalParameters.single.isCovariantByClass = true;
  }

  @override
  Field get field => _field;

  @override
  Member get builtMember => _field;

  @override
  Iterable<Annotatable> get annotatables {
    List<Annotatable> list = [_lateGetter];
    if (_lateSetter != null) {
      list.add(_lateSetter!);
    }
    return list;
  }

  @override
  Member get readTarget => _lateGetter;

  @override
  Reference get readTargetReference => _lateGetter.reference;

  @override
  Member? get writeTarget => _lateSetter;

  @override
  Reference? get writeTargetReference => _lateSetter?.reference;

  @override
  Iterable<Reference> get exportedReferenceMembers {
    if (_lateSetter != null) {
      return [_lateGetter.reference, _lateSetter!.reference];
    }
    return [_lateGetter.reference];
  }

  @override
  void build(
      SourceLibraryBuilder libraryBuilder, SourceFieldBuilder fieldBuilder) {
    bool isInstanceMember = !fieldBuilder.isStatic && !fieldBuilder.isTopLevel;
    bool isExtensionMember = fieldBuilder.isExtensionMember;
    bool isExtensionTypeMember = fieldBuilder.isExtensionTypeMember;
    if (isExtensionMember) {
      _field
        ..isStatic = true
        ..isExtensionMember = isExtensionMember;
      isInstanceMember = false;
    } else if (isExtensionTypeMember) {
      _field
        ..isStatic = fieldBuilder.isStatic
        ..isExtensionTypeMember = true;
    } else {
      _field
        ..isStatic = !isInstanceMember
        ..isExtensionMember = false;
    }
    if (_lateIsSetField != null) {
      _lateIsSetField!
        ..isStatic = !isInstanceMember
        ..isExtensionMember = isExtensionMember
        ..isExtensionTypeMember = isExtensionTypeMember
        ..type = libraryBuilder.loader
            .createCoreType('bool', Nullability.nonNullable);
    }
    _lateGetter
      ..isStatic = !isInstanceMember
      ..isExtensionMember = isExtensionMember
      ..isExtensionTypeMember = isExtensionTypeMember;
    if (_lateSetter != null) {
      _lateSetter!
        ..isStatic = !isInstanceMember
        ..isExtensionMember = isExtensionMember
        ..isExtensionTypeMember = isExtensionTypeMember;
    }
  }

  @override
  void registerMembers(SourceLibraryBuilder library,
      SourceFieldBuilder fieldBuilder, BuildNodesCallback f) {
    f(
        member: _field,
        kind:
            fieldBuilder.isExtensionMember || fieldBuilder.isExtensionTypeMember
                ? BuiltMemberKind.ExtensionField
                : BuiltMemberKind.Field);
    if (_lateIsSetField != null) {
      _forceIncludeIsSetField = true;
      f(member: _lateIsSetField!, kind: BuiltMemberKind.LateIsSetField);
    }
    f(member: _lateGetter, kind: BuiltMemberKind.LateGetter);
    if (_lateSetter != null) {
      f(member: _lateSetter!, kind: BuiltMemberKind.LateSetter);
    }
  }

  @override
  List<ClassMember> getLocalMembers(SourceFieldBuilder fieldBuilder) {
    List<ClassMember> list = <ClassMember>[
      new _SynthesizedFieldClassMember(fieldBuilder, field, field.name,
          _SynthesizedFieldMemberKind.LateField, ClassMemberKind.Getter,
          isInternalImplementation: true),
      new _SynthesizedFieldClassMember(
          fieldBuilder,
          _lateGetter,
          fieldBuilder.memberName,
          _SynthesizedFieldMemberKind.LateGetterSetter,
          ClassMemberKind.Getter,
          isInternalImplementation: false)
    ];
    if (_lateIsSetField != null) {
      list.add(new _SynthesizedFieldClassMember(
          fieldBuilder,
          _lateIsSetField!,
          _lateIsSetField!.name,
          _SynthesizedFieldMemberKind.LateIsSet,
          ClassMemberKind.Getter,
          isInternalImplementation: true));
    }
    return list;
  }

  @override
  List<ClassMember> getLocalSetters(SourceFieldBuilder fieldBuilder) {
    List<ClassMember> list = <ClassMember>[
      new _SynthesizedFieldClassMember(fieldBuilder, field, field.name,
          _SynthesizedFieldMemberKind.LateField, ClassMemberKind.Setter,
          isInternalImplementation: true),
    ];
    if (_lateIsSetField != null) {
      list.add(new _SynthesizedFieldClassMember(
          fieldBuilder,
          _lateIsSetField!,
          _lateIsSetField!.name,
          _SynthesizedFieldMemberKind.LateIsSet,
          ClassMemberKind.Setter,
          isInternalImplementation: true));
    }
    if (_lateSetter != null) {
      list.add(new _SynthesizedFieldClassMember(
          fieldBuilder,
          _lateSetter!,
          fieldBuilder.memberName,
          _SynthesizedFieldMemberKind.LateGetterSetter,
          ClassMemberKind.Setter,
          isInternalImplementation: false));
    }
    return list;
  }
}

mixin NonFinalLate on AbstractLateFieldEncoding {
  @override
  // Coverage-ignore(suite): Not run.
  Statement _createSetterBody(
      CoreTypes coreTypes, String name, VariableDeclaration parameter) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createSetterBody(
        coreTypes, fileOffset, name, parameter, _type!,
        shouldReturnValue: false,
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field, value),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField!, value),
        isSetEncoding: isSetEncoding);
  }
}

mixin LateWithoutInitializer on AbstractLateFieldEncoding {
  @override
  // Coverage-ignore(suite): Not run.
  Statement _createGetterBody(
      CoreTypes coreTypes, String name, Expression? initializer) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterBodyWithoutInitializer(
        coreTypes, fileOffset, name, type,
        createVariableRead: _createFieldRead,
        createIsSetRead: () => _createFieldGet(_lateIsSetField!),
        isSetEncoding: isSetEncoding,
        forField: true);
  }

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("$runtimeType.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("$runtimeType.buildImplicitInitializer");
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    throw new UnsupportedError("$runtimeType.buildDuplicatedInitializer");
  }
}

// Coverage-ignore(suite): Not run.
class LateFieldWithoutInitializerEncoding extends AbstractLateFieldEncoding
    with NonFinalLate, LateWithoutInitializer {
  LateFieldWithoutInitializerEncoding(
      {required super.name,
      required super.nameScheme,
      required super.fileUri,
      required super.nameOffset,
      required super.endOffset,
      required super.fieldReference,
      required super.fieldGetterReference,
      required super.fieldSetterReference,
      required super.lateIsSetFieldReference,
      required super.lateIsSetGetterReference,
      required super.lateIsSetSetterReference,
      required super.lateGetterReference,
      required super.lateSetterReference,
      required super.isCovariantByDeclaration,
      required super.isSetStrategy});
}

// Coverage-ignore(suite): Not run.
class LateFieldWithInitializerEncoding extends AbstractLateFieldEncoding
    with NonFinalLate {
  LateFieldWithInitializerEncoding(
      {required super.name,
      required super.nameScheme,
      required super.fileUri,
      required super.nameOffset,
      required super.endOffset,
      required super.fieldReference,
      required super.fieldGetterReference,
      required super.fieldSetterReference,
      required super.lateIsSetFieldReference,
      required super.lateIsSetGetterReference,
      required super.lateIsSetSetterReference,
      required super.lateGetterReference,
      required super.lateSetterReference,
      required super.isCovariantByDeclaration,
      required super.isSetStrategy});

  @override
  Statement _createGetterBody(
      CoreTypes coreTypes, String name, Expression? initializer) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterWithInitializer(
        coreTypes, fileOffset, name, _type!, initializer!,
        createVariableRead: _createFieldRead,
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field, value),
        createIsSetRead: () => _createFieldGet(_lateIsSetField!),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField!, value),
        isSetEncoding: isSetEncoding);
  }

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("$runtimeType.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("$runtimeType.buildImplicitInitializer");
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    throw new UnsupportedError("$runtimeType.buildDuplicatedInitializer");
  }
}

// Coverage-ignore(suite): Not run.
class LateFinalFieldWithoutInitializerEncoding extends AbstractLateFieldEncoding
    with LateWithoutInitializer {
  LateFinalFieldWithoutInitializerEncoding(
      {required super.name,
      required super.nameScheme,
      required super.fileUri,
      required super.nameOffset,
      required super.endOffset,
      required super.fieldReference,
      required super.fieldGetterReference,
      required super.fieldSetterReference,
      required super.lateIsSetFieldReference,
      required super.lateIsSetGetterReference,
      required super.lateIsSetSetterReference,
      required super.lateGetterReference,
      required super.lateSetterReference,
      required super.isCovariantByDeclaration,
      required super.isSetStrategy});

  @override
  Statement _createSetterBody(
      CoreTypes coreTypes, String name, VariableDeclaration parameter) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createSetterBodyFinal(
        coreTypes, fileOffset, name, parameter, type,
        shouldReturnValue: false,
        createVariableRead: () => _createFieldGet(_field),
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field, value),
        createIsSetRead: () => _createFieldGet(_lateIsSetField!),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField!, value),
        isSetEncoding: isSetEncoding,
        forField: true);
  }
}

// Coverage-ignore(suite): Not run.
class LateFinalFieldWithInitializerEncoding extends AbstractLateFieldEncoding {
  LateFinalFieldWithInitializerEncoding(
      {required super.name,
      required super.nameScheme,
      required super.fileUri,
      required super.nameOffset,
      required super.endOffset,
      required super.fieldReference,
      required super.fieldGetterReference,
      required super.fieldSetterReference,
      required super.lateIsSetFieldReference,
      required super.lateIsSetGetterReference,
      required super.lateIsSetSetterReference,
      required super.lateGetterReference,
      required super.lateSetterReference,
      required super.isCovariantByDeclaration,
      required super.isSetStrategy});

  @override
  Statement _createGetterBody(
      CoreTypes coreTypes, String name, Expression? initializer) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterWithInitializerWithRecheck(
        coreTypes, fileOffset, name, _type!, initializer!,
        createVariableRead: _createFieldRead,
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field, value),
        createIsSetRead: () => _createFieldGet(_lateIsSetField!),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField!, value),
        isSetEncoding: isSetEncoding,
        forField: true);
  }

  @override
  Procedure? _createSetter(Uri fileUri, int charOffset, Reference? reference,
          {required bool isCovariantByDeclaration}) =>
      null;

  @override
  Statement _createSetterBody(
          CoreTypes coreTypes, String name, VariableDeclaration parameter) =>
      throw new UnsupportedError(
          '$runtimeType._createSetterBody is not supported.');

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("$runtimeType.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("$runtimeType.buildImplicitInitializer");
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    throw new UnsupportedError("$runtimeType.buildDuplicatedInitializer");
  }
}

// Coverage-ignore(suite): Not run.
class _SynthesizedFieldClassMember implements ClassMember {
  final SourceFieldBuilder fieldBuilder;
  final _SynthesizedFieldMemberKind _kind;

  final Member _member;

  final Name _name;

  Covariance? _covariance;

  @override
  final bool isInternalImplementation;

  @override
  final ClassMemberKind memberKind;

  _SynthesizedFieldClassMember(
      this.fieldBuilder, this._member, this._name, this._kind, this.memberKind,
      {required this.isInternalImplementation});

  @override
  Member getMember(ClassMembersBuilder membersBuilder) {
    fieldBuilder._ensureType(membersBuilder);
    return _member;
  }

  @override
  Member? getTearOff(ClassMembersBuilder membersBuilder) {
    // Ensure field type is computed.
    getMember(membersBuilder);
    return null;
  }

  @override
  Covariance getCovariance(ClassMembersBuilder membersBuilder) {
    return _covariance ??= new Covariance.fromMember(getMember(membersBuilder),
        forSetter: forSetter);
  }

  @override
  MemberResult getMemberResult(ClassMembersBuilder membersBuilder) {
    return new TypeDeclarationInstanceMemberResult(
        getMember(membersBuilder), memberKind,
        isDeclaredAsField: true);
  }

  @override
  void inferType(ClassMembersBuilder membersBuilder) {
    fieldBuilder._ensureType(membersBuilder);
  }

  @override
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    fieldBuilder.registerOverrideDependency(overriddenMembers);
  }

  @override
  bool get isSourceDeclaration => true;

  @override
  bool get forSetter => memberKind == ClassMemberKind.Setter;

  @override
  bool get isProperty => memberKind != ClassMemberKind.Method;

  @override
  DeclarationBuilder get declarationBuilder => fieldBuilder.declarationBuilder!;

  @override
  bool isObjectMember(ClassBuilder objectClass) {
    return declarationBuilder == objectClass;
  }

  @override
  bool get isDuplicate => fieldBuilder.isDuplicate;

  @override
  bool get isStatic => fieldBuilder.isStatic;

  @override
  bool get isField => _member is Field;

  @override
  bool get isSetter {
    Member procedure = _member;
    return procedure is Procedure && procedure.kind == ProcedureKind.Setter;
  }

  @override
  bool get isGetter {
    Member procedure = _member;
    return procedure is Procedure && procedure.kind == ProcedureKind.Getter;
  }

  @override
  Name get name => _name;

  @override
  String get fullName {
    String suffix = isSetter ? "=" : "";
    String className = declarationBuilder.fullNameForErrors;
    return "${className}.${fullNameForErrors}$suffix";
  }

  @override
  String get fullNameForErrors => fieldBuilder.fullNameForErrors;

  @override
  Uri get fileUri => fieldBuilder.fileUri;

  @override
  int get charOffset => fieldBuilder.fileOffset;

  @override
  bool get isAbstract => _member.isAbstract;

  @override
  bool get isSynthesized => false;

  @override
  bool get hasDeclarations => false;

  @override
  List<ClassMember> get declarations =>
      throw new UnsupportedError("$runtimeType.declarations");

  @override
  ClassMember get interfaceMember => this;

  @override
  bool isSameDeclaration(ClassMember other) {
    if (identical(this, other)) return true;
    return other is _SynthesizedFieldClassMember &&
        fieldBuilder == other.fieldBuilder &&
        _kind == other._kind;
  }

  @override
  bool get isNoSuchMethodForwarder => false;

  @override
  String toString() => '_SynthesizedFieldClassMember('
      '$fieldBuilder,$_member,$_kind,forSetter=${forSetter})';

  @override
  bool get isExtensionTypeMember => fieldBuilder.isExtensionTypeMember;
}

// Coverage-ignore(suite): Not run.
class AbstractOrExternalFieldEncoding implements FieldEncoding {
  final SourceFieldBuilder _fieldBuilder;
  final bool isAbstract;
  final bool isExternal;
  final bool _isExtensionInstanceMember;
  final bool _isExtensionTypeInstanceMember;

  late Procedure _getter;
  Procedure? _setter;
  DartType? _type;

  AbstractOrExternalFieldEncoding(
      this._fieldBuilder,
      String name,
      NameScheme nameScheme,
      Uri fileUri,
      int nameOffset,
      int endOffset,
      Reference? getterReference,
      Reference? setterReference,
      {required this.isAbstract,
      required this.isExternal,
      required bool isFinal,
      required bool isCovariantByDeclaration,
      bool isForcedExtension = false})
      : _isExtensionInstanceMember = (isExternal || isForcedExtension) &&
            nameScheme.isExtensionMember &&
            nameScheme.isInstanceMember,
        _isExtensionTypeInstanceMember = (isExternal || isForcedExtension) &&
            nameScheme.isExtensionTypeMember &&
            nameScheme.isInstanceMember {
    if (_isExtensionInstanceMember || _isExtensionTypeInstanceMember) {
      _getter = new Procedure(
          dummyName,
          ProcedureKind.Method,
          new FunctionNode(null, positionalParameters: [
            new VariableDeclaration(syntheticThisName)
              ..fileOffset = nameOffset
              ..isLowered = true
          ]),
          fileUri: fileUri,
          reference: getterReference)
        ..fileOffset = nameOffset
        ..fileEndOffset = endOffset;
      nameScheme
          .getProcedureMemberName(ProcedureKind.Getter, name)
          .attachMember(_getter);
      if (!isFinal) {
        VariableDeclaration parameter =
            new VariableDeclaration("#externalFieldValue", isSynthesized: true)
              ..isCovariantByDeclaration = isCovariantByDeclaration
              ..fileOffset = nameOffset;
        _setter = new Procedure(
            dummyName,
            ProcedureKind.Method,
            new FunctionNode(null,
                positionalParameters: [
                  new VariableDeclaration(syntheticThisName)
                    ..fileOffset = nameOffset
                    ..isLowered = true,
                  parameter
                ],
                returnType: const VoidType())
              ..fileOffset = nameOffset
              ..fileEndOffset = endOffset,
            fileUri: fileUri,
            reference: setterReference)
          ..fileOffset = nameOffset
          ..fileEndOffset = endOffset;
        nameScheme
            .getProcedureMemberName(ProcedureKind.Setter, name)
            .attachMember(_setter!);
      }
    } else {
      _getter = new Procedure(
          dummyName, ProcedureKind.Getter, new FunctionNode(null),
          fileUri: fileUri, reference: getterReference)
        ..fileOffset = nameOffset
        ..fileEndOffset = endOffset;
      nameScheme
          .getFieldMemberName(FieldNameType.Getter, name, isSynthesized: true)
          .attachMember(_getter);
      if (!isFinal) {
        VariableDeclaration parameter =
            new VariableDeclaration("#externalFieldValue", isSynthesized: true)
              ..isCovariantByDeclaration = isCovariantByDeclaration
              ..fileOffset = nameOffset;
        _setter = new Procedure(
            dummyName,
            ProcedureKind.Setter,
            new FunctionNode(null,
                positionalParameters: [parameter], returnType: const VoidType())
              ..fileOffset = nameOffset
              ..fileEndOffset = endOffset,
            fileUri: fileUri,
            reference: setterReference)
          ..fileOffset = nameOffset
          ..fileEndOffset = endOffset;
        nameScheme
            .getFieldMemberName(FieldNameType.Setter, name, isSynthesized: true)
            .attachMember(_setter!);
      }
    }
  }

  @override
  DartType get type {
    assert(_type != null,
        "Type has not been computed for field ${_fieldBuilder.name}.");
    return _type!;
  }

  @override
  void set type(DartType value) {
    assert(_type == null || _type is InferredType,
        "Type has already been computed for field ${_fieldBuilder.name}.");
    _type = value;
    if (value is! InferredType) {
      if (_isExtensionInstanceMember || _isExtensionTypeInstanceMember) {
        DartType thisParameterType;
        List<TypeParameter> typeParameters;
        if (_isExtensionInstanceMember) {
          SourceExtensionBuilder extensionBuilder =
              _fieldBuilder.parent as SourceExtensionBuilder;
          thisParameterType = extensionBuilder.extension.onType;
          typeParameters = extensionBuilder.extension.typeParameters;
        } else {
          SourceExtensionTypeDeclarationBuilder
              extensionTypeDeclarationBuilder =
              _fieldBuilder.parent as SourceExtensionTypeDeclarationBuilder;
          thisParameterType = extensionTypeDeclarationBuilder
              .extensionTypeDeclaration.declaredRepresentationType;
          typeParameters = extensionTypeDeclarationBuilder
              .extensionTypeDeclaration.typeParameters;
        }
        if (typeParameters.isNotEmpty) {
          FreshTypeParameters getterTypeParameters =
              getFreshTypeParameters(typeParameters);
          _getter.function.positionalParameters.first.type =
              getterTypeParameters.substitute(thisParameterType);
          _getter.function.returnType = getterTypeParameters.substitute(value);
          _getter.function.typeParameters =
              getterTypeParameters.freshTypeParameters;
          setParents(
              getterTypeParameters.freshTypeParameters, _getter.function);

          Procedure? setter = _setter;
          if (setter != null) {
            FreshTypeParameters setterTypeParameters =
                getFreshTypeParameters(typeParameters);
            setter.function.positionalParameters.first.type =
                setterTypeParameters.substitute(thisParameterType);
            setter.function.positionalParameters[1].type =
                setterTypeParameters.substitute(value);
            setter.function.typeParameters =
                setterTypeParameters.freshTypeParameters;
            setParents(
                setterTypeParameters.freshTypeParameters, setter.function);
          }
        } else {
          _getter.function.returnType = value;
          _setter?.function.positionalParameters[1].type = value;
          _getter.function.positionalParameters.first.type = thisParameterType;
          _setter?.function.positionalParameters.first.type = thisParameterType;
        }
      } else {
        _getter.function.returnType = value;
        Procedure? setter = _setter;
        if (setter != null) {
          if (setter.kind == ProcedureKind.Method) {
            setter.function.positionalParameters[1].type = value;
          } else {
            setter.function.positionalParameters.first.type = value;
          }
        }
      }
    }
  }

  @override
  void createBodies(CoreTypes coreTypes, Expression? initializer) {
    // TODO(johnniwinther): Enable this assert.
    //assert(initializer != null);
  }

  @override
  List<Initializer> createInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    throw new UnsupportedError('ExternalFieldEncoding.createInitializer');
  }

  @override
  void build(
      SourceLibraryBuilder libraryBuilder, SourceFieldBuilder fieldBuilder) {
    bool isExtensionMember = fieldBuilder.isExtensionMember;
    bool isExtensionTypeMember = fieldBuilder.isExtensionTypeMember;
    bool isInstanceMember = !isExtensionMember &&
        !isExtensionTypeMember &&
        !fieldBuilder.isStatic &&
        !fieldBuilder.isTopLevel;
    _getter..isConst = fieldBuilder.isConst;
    _getter
      ..isStatic = !isInstanceMember
      ..isExtensionMember = isExtensionMember
      ..isExtensionTypeMember = isExtensionTypeMember
      ..isAbstract = isAbstract && !isExternal
      ..isExternal = isExternal;

    if (_setter != null) {
      _setter!
        ..isStatic = !isInstanceMember
        ..isExtensionMember = isExtensionMember
        ..isExtensionTypeMember = isExtensionTypeMember
        ..isAbstract = isAbstract && !isExternal
        ..isExternal = isExternal;
    }
  }

  @override
  void registerMembers(SourceLibraryBuilder library,
      SourceFieldBuilder fieldBuilder, BuildNodesCallback f) {
    BuiltMemberKind getterMemberKind;
    if (fieldBuilder.isExtensionMember) {
      getterMemberKind = BuiltMemberKind.ExtensionGetter;
    } else if (fieldBuilder.isExtensionTypeMember) {
      getterMemberKind = BuiltMemberKind.ExtensionTypeGetter;
    } else {
      getterMemberKind = BuiltMemberKind.Method;
    }
    f(member: _getter, kind: getterMemberKind);
    if (_setter != null) {
      BuiltMemberKind setterMemberKind;
      if (fieldBuilder.isExtensionMember) {
        setterMemberKind = BuiltMemberKind.ExtensionSetter;
      } else if (fieldBuilder.isExtensionTypeMember) {
        setterMemberKind = BuiltMemberKind.ExtensionTypeSetter;
      } else {
        setterMemberKind = BuiltMemberKind.Method;
      }
      f(member: _setter!, kind: setterMemberKind);
    }
  }

  @override
  void setGenericCovariantImpl() {
    _setter!.function.positionalParameters.first.isCovariantByClass = true;
  }

  @override
  Field get field {
    throw new UnsupportedError("ExternalFieldEncoding.field");
  }

  @override
  Member get builtMember => _getter;

  @override
  Iterable<Annotatable> get annotatables {
    List<Annotatable> list = [_getter];
    if (_setter != null) {
      list.add(_setter!);
    }
    return list;
  }

  @override
  Member get readTarget => _getter;

  @override
  Reference get readTargetReference => _getter.reference;

  @override
  Member? get writeTarget => _setter;

  @override
  Reference? get writeTargetReference => _setter?.reference;

  @override
  Iterable<Reference> get exportedReferenceMembers {
    if (_setter != null) {
      return [_getter.reference, _setter!.reference];
    }
    return [_getter.reference];
  }

  @override
  List<ClassMember> getLocalMembers(SourceFieldBuilder fieldBuilder) =>
      <ClassMember>[
        new _SynthesizedFieldClassMember(
            fieldBuilder,
            _getter,
            fieldBuilder.memberName,
            _SynthesizedFieldMemberKind.AbstractExternalGetterSetter,
            ClassMemberKind.Getter,
            isInternalImplementation: false)
      ];

  @override
  List<ClassMember> getLocalSetters(SourceFieldBuilder fieldBuilder) =>
      _setter != null
          ? <ClassMember>[
              new _SynthesizedFieldClassMember(
                  fieldBuilder,
                  _setter!,
                  fieldBuilder.memberName,
                  _SynthesizedFieldMemberKind.AbstractExternalGetterSetter,
                  ClassMemberKind.Setter,
                  isInternalImplementation: false)
            ]
          : const <ClassMember>[];

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("$runtimeType.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("$runtimeType.buildImplicitInitializer");
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    return new ShadowInvalidFieldInitializer(type, value, effect)
      ..fileOffset = fileOffset;
  }
}

// Coverage-ignore(suite): Not run.
/// The encoding of an extension type declaration representation field.
class RepresentationFieldEncoding implements FieldEncoding {
  final SourceFieldBuilder _fieldBuilder;

  late Procedure _getter;
  DartType? _type;

  RepresentationFieldEncoding(
      this._fieldBuilder,
      String name,
      NameScheme nameScheme,
      Uri fileUri,
      int charOffset,
      int charEndOffset,
      Reference? getterReference) {
    _getter = new Procedure(
        dummyName, ProcedureKind.Getter, new FunctionNode(null),
        fileUri: fileUri, reference: getterReference)
      ..stubKind = ProcedureStubKind.RepresentationField
      ..fileOffset = charOffset
      ..fileEndOffset = charEndOffset;
    nameScheme
        .getFieldMemberName(FieldNameType.RepresentationField, name,
            isSynthesized: true)
        .attachMember(_getter);
  }

  @override
  DartType get type {
    assert(_type != null,
        "Type has not been computed for field ${_fieldBuilder.name}.");
    return _type!;
  }

  @override
  void set type(DartType value) {
    assert(_type == null || _type is InferredType,
        "Type has already been computed for field ${_fieldBuilder.name}.");
    _type = value;
    if (value is! InferredType) {
      _getter.function.returnType = value;
    }
  }

  @override
  void createBodies(CoreTypes coreTypes, Expression? initializer) {
    // TODO(johnniwinther): Enable this assert.
    //assert(initializer != null);
  }

  @override
  List<Initializer> createInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    return <Initializer>[
      new ExtensionTypeRepresentationFieldInitializer(_getter, value)
    ];
  }

  @override
  void build(
      SourceLibraryBuilder libraryBuilder, SourceFieldBuilder fieldBuilder) {
    _getter..isConst = fieldBuilder.isConst;
    _getter
      ..isStatic = false
      ..isExtensionMember = false
      ..isExtensionTypeMember = true
      ..isAbstract = true
      ..isExternal = false;
  }

  @override
  void registerMembers(SourceLibraryBuilder library,
      SourceFieldBuilder fieldBuilder, BuildNodesCallback f) {
    f(member: _getter, kind: BuiltMemberKind.ExtensionTypeRepresentationField);
  }

  @override
  void setGenericCovariantImpl() {
    throw new UnsupportedError("$runtimeType.setGenericCovariantImpl");
  }

  @override
  Field get field {
    throw new UnsupportedError("$runtimeType.field");
  }

  @override
  Member get builtMember => _getter;

  @override
  Iterable<Annotatable> get annotatables => [_getter];

  @override
  Member get readTarget => _getter;

  @override
  Reference get readTargetReference => _getter.reference;

  @override
  Member? get writeTarget => null;

  @override
  Reference? get writeTargetReference => null;

  @override
  Iterable<Reference> get exportedReferenceMembers => [_getter.reference];

  @override
  List<ClassMember> getLocalMembers(SourceFieldBuilder fieldBuilder) =>
      <ClassMember>[
        new _SynthesizedFieldClassMember(
            fieldBuilder,
            _getter,
            fieldBuilder.memberName,
            _SynthesizedFieldMemberKind.RepresentationField,
            ClassMemberKind.Getter,
            isInternalImplementation: false)
      ];

  @override
  List<ClassMember> getLocalSetters(SourceFieldBuilder fieldBuilder) =>
      const <ClassMember>[];

  @override
  void buildImplicitDefaultValue() {
    // Not needed.
  }

  @override
  Initializer buildImplicitInitializer() {
    return new ExtensionTypeRepresentationFieldInitializer(
        _getter, new NullLiteral());
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    return new ShadowInvalidFieldInitializer(type, value, effect)
      ..fileOffset = fileOffset;
  }
}

enum _SynthesizedFieldMemberKind {
  /// A `isSet` field used for late lowering.
  LateIsSet,

  /// A field used for the value of a late lowered field.
  LateField,

  /// A getter or setter used for late lowering.
  LateGetterSetter,

  /// A getter or setter used for abstract or external fields.
  AbstractExternalGetterSetter,

  /// A getter for an extension type declaration representation field.
  RepresentationField,
}
