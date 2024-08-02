// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.enum_builder;

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/reference_from_index.dart' show IndexedClass;
import 'package:kernel/src/bounds_checks.dart';
import 'package:kernel/transformations/flags.dart';

import '../base/constant_context.dart';
import '../base/modifier.dart' show constMask, hasInitializerMask, staticMask;
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_builder.dart';
import '../codes/cfe_codes.dart'
    show
        LocatedMessage,
        Severity,
        messageEnumContainsValuesDeclaration,
        messageEnumNonConstConstructor,
        messageEnumWithNameValues,
        messageNoUnnamedConstructorInObject,
        noLength,
        templateConstructorNotFound,
        templateDuplicatedDeclaration,
        templateDuplicatedDeclarationCause,
        templateDuplicatedDeclarationSyntheticCause,
        templateEnumContainsRestrictedInstanceDeclaration,
        templateEnumConstantSameNameAsEnclosing;
import '../kernel/body_builder.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/constness.dart';
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/expression_generator_helper.dart';
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/type_schema.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart' show SourceClassBuilder;
import 'source_constructor_builder.dart';
import 'source_field_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_procedure_builder.dart';
import 'type_parameter_scope_builder.dart';

class SourceEnumBuilder extends SourceClassBuilder {
  final int startCharOffset;
  final int charEndOffset;

  final List<EnumConstantInfo?>? enumConstantInfos;

  late final NamedTypeBuilder intType;

  late final NamedTypeBuilder stringType;

  late final NamedTypeBuilder objectType;

  late final NamedTypeBuilder listType;

  late final NamedTypeBuilder selfType;

  DeclaredSourceConstructorBuilder? synthesizedDefaultConstructorBuilder;

  final List<SourceFieldBuilder> elementBuilders = [];

  final Set<SourceFieldBuilder> _builtElements =
      new Set<SourceFieldBuilder>.identity();

  SourceEnumBuilder.internal(
      List<MetadataBuilder>? metadata,
      String name,
      List<NominalVariableBuilder>? typeVariables,
      TypeBuilder supertypeBuilder,
      List<TypeBuilder>? interfaceBuilders,
      LookupScope typeParameterScope,
      DeclarationNameSpaceBuilder nameSpaceBuilder,
      this.enumConstantInfos,
      SourceLibraryBuilder parent,
      List<ConstructorReferenceBuilder> constructorReferences,
      this.startCharOffset,
      int charOffset,
      this.charEndOffset,
      IndexedClass? referencesFromIndexed)
      : super(
            metadata,
            0,
            name,
            typeVariables,
            supertypeBuilder,
            interfaceBuilders,
            /* onTypes = */ null,
            typeParameterScope,
            nameSpaceBuilder,
            parent,
            constructorReferences,
            startCharOffset,
            charOffset,
            charEndOffset,
            referencesFromIndexed);

  factory SourceEnumBuilder(
      List<MetadataBuilder>? metadata,
      String name,
      List<NominalVariableBuilder>? typeVariables,
      TypeBuilder? supertypeBuilder,
      List<TypeBuilder>? interfaceBuilders,
      List<EnumConstantInfo?>? enumConstantInfos,
      SourceLibraryBuilder libraryBuilder,
      List<ConstructorReferenceBuilder> constructorReferences,
      int startCharOffset,
      int charOffset,
      int charEndOffset,
      IndexedClass? referencesFromIndexed,
      LookupScope typeParameterScope,
      DeclarationNameSpaceBuilder nameSpaceBuilder) {
    final int startCharOffsetComputed =
        metadata == null ? startCharOffset : metadata.first.charOffset;
    // Coverage-ignore(suite): Not run.
    supertypeBuilder ??= new NamedTypeBuilderImpl(
        const PredefinedTypeName("_Enum"), const NullabilityBuilder.omitted(),
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);
    SourceEnumBuilder enumBuilder = new SourceEnumBuilder.internal(
        metadata,
        name,
        typeVariables,
        supertypeBuilder,
        interfaceBuilders,
        typeParameterScope,
        nameSpaceBuilder,
        enumConstantInfos,
        libraryBuilder,
        constructorReferences,
        startCharOffsetComputed,
        charOffset,
        charEndOffset,
        referencesFromIndexed);
    return enumBuilder;
  }

  @override
  void buildScopes(LibraryBuilder coreLibrary) {
    _createSynthesizedMembers(coreLibrary);
    super.buildScopes(coreLibrary);

    Iterator<MemberBuilder> iterator =
        nameSpace.filteredConstructorNameIterator(
            includeDuplicates: false, includeAugmentations: true);
    while (iterator.moveNext()) {
      MemberBuilder member = iterator.current;
      if (member is DeclaredSourceConstructorBuilder) {
        member.ensureGrowableFormals();
        member.formals!.insert(
            0,
            new FormalParameterBuilder(
                FormalParameterKind.requiredPositional,
                /* modifiers = */ 0,
                stringType,
                "#name",
                libraryBuilder,
                charOffset,
                fileUri: fileUri,
                hasImmediatelyDeclaredInitializer: false));
        member.formals!.insert(
            0,
            new FormalParameterBuilder(
                FormalParameterKind.requiredPositional,
                /* modifiers = */ 0,
                intType,
                "#index",
                libraryBuilder,
                charOffset,
                fileUri: fileUri,
                hasImmediatelyDeclaredInitializer: false));
      }
    }

    Iterator<MemberBuilder> constructorIterator =
        nameSpace.filteredConstructorIterator(
            includeDuplicates: false, includeAugmentations: true);
    while (constructorIterator.moveNext()) {
      MemberBuilder constructorBuilder = constructorIterator.current;
      if (!constructorBuilder.isFactory && !constructorBuilder.isConst) {
        libraryBuilder.addProblem(messageEnumNonConstConstructor,
            constructorBuilder.charOffset, noLength, fileUri);
      }
    }
  }

  void _createSynthesizedMembers(LibraryBuilder coreLibrary) {
    assert(enumConstantInfos == null || enumConstantInfos!.isNotEmpty);

    // TODO(ahe): These types shouldn't be looked up in scope, they come
    // directly from dart:core.
    intType = new NamedTypeBuilderImpl(
        const PredefinedTypeName("int"), const NullabilityBuilder.omitted(),
        instanceTypeVariableAccess:
            // If "int" resolves to an instance type variable then that we would
            // allowed (the types that we are adding are in instance context
            // after all) but it would be unexpected and we would like an
            // assertion failure, since "int" was meant to be `int` from
            // `dart:core`.
            // TODO(johnniwinther): Add a more robust way of creating named
            // typed builders for dart:core types. This might be needed for the
            // enhanced enums feature where enums can actually declare type
            // variables.
            InstanceTypeVariableAccessState.Unexpected);
    stringType = new NamedTypeBuilderImpl(
        const PredefinedTypeName("String"), const NullabilityBuilder.omitted(),
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);
    objectType = new NamedTypeBuilderImpl(
        const PredefinedTypeName("Object"), const NullabilityBuilder.omitted(),
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);
    selfType = new NamedTypeBuilderImpl(new SyntheticTypeName(name, charOffset),
        const NullabilityBuilder.omitted(),
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected,
        fileUri: fileUri,
        charOffset: charOffset);
    listType = new NamedTypeBuilderImpl(
        const PredefinedTypeName("List"), const NullabilityBuilder.omitted(),
        arguments: <TypeBuilder>[selfType],
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);

    // metadata class E extends _Enum {
    //   const E(int index, String name) : super(index, name);
    //   static const E id0 = const E(0, 'id0');
    //   ...
    //   static const E id${n-1} = const E(n - 1, 'idn-1');
    //   static const List<E> values = const <E>[id0, ..., id${n-1}];
    //   String _enumToString() {
    //     return "E.${_Enum::_name}";
    //   }
    // }

    LibraryName libraryName = indexedClass != null
        ? new LibraryName(indexedClass!.library.reference)
        : libraryBuilder.libraryName;

    NameScheme staticFieldNameScheme = new NameScheme(
        isInstanceMember: false,
        containerName: new ClassName(name),
        containerType: ContainerType.Class,
        libraryName: libraryName);

    Reference? constructorReference;
    Reference? tearOffReference;
    Reference? toStringReference;
    Reference? valuesFieldReference;
    Reference? valuesGetterReference;
    Reference? valuesSetterReference;
    if (indexedClass != null) {
      constructorReference =
          indexedClass!.lookupConstructorReference(new Name(""));
      tearOffReference = indexedClass!.lookupGetterReference(
          new Name(constructorTearOffName(""), indexedClass!.library));
      toStringReference = indexedClass!.lookupGetterReference(
          new Name("_enumToString", coreLibrary.library));
      Name valuesName = new Name("values");
      valuesFieldReference = indexedClass!.lookupFieldReference(valuesName);
      valuesGetterReference = indexedClass!.lookupGetterReference(valuesName);
      valuesSetterReference = indexedClass!.lookupSetterReference(valuesName);
    }

    Builder? customValuesDeclaration =
        nameSpaceBuilder.lookupLocalMember("values", setter: false);
    if (customValuesDeclaration != null) {
      // Retrieve the earliest declaration for error reporting.
      while (customValuesDeclaration?.next != null) {
        customValuesDeclaration = customValuesDeclaration?.next;
      }
      libraryBuilder.addProblem(
          messageEnumContainsValuesDeclaration,
          customValuesDeclaration!.charOffset,
          customValuesDeclaration.fullNameForErrors.length,
          fileUri);
    }

    for (String restrictedInstanceMemberName in const [
      "index",
      "hashCode",
      "=="
    ]) {
      Builder? customIndexDeclaration = nameSpaceBuilder
          .lookupLocalMember(restrictedInstanceMemberName, setter: false);
      if (customIndexDeclaration is MemberBuilder &&
          !customIndexDeclaration.isAbstract) {
        // Retrieve the earliest declaration for error reporting.
        while (customIndexDeclaration?.next != null) {
          // Coverage-ignore-block(suite): Not run.
          customIndexDeclaration = customIndexDeclaration?.next;
        }
        libraryBuilder.addProblem(
            templateEnumContainsRestrictedInstanceDeclaration
                .withArguments(restrictedInstanceMemberName),
            customIndexDeclaration!.charOffset,
            customIndexDeclaration.fullNameForErrors.length,
            fileUri);
      }
    }

    SourceFieldBuilder valuesBuilder = new SourceFieldBuilder(
        /* metadata = */ null,
        listType,
        "values",
        constMask | staticMask | hasInitializerMask,
        /* isTopLevel = */ false,
        libraryBuilder,
        fileUri,
        charOffset,
        charOffset,
        staticFieldNameScheme,
        fieldReference: valuesFieldReference,
        fieldGetterReference: valuesGetterReference,
        fieldSetterReference: valuesSetterReference,
        isSynthesized: true);
    if (customValuesDeclaration != null) {
      customValuesDeclaration.next = valuesBuilder;
    } else {
      nameSpaceBuilder.addLocalMember("values", valuesBuilder, setter: false);
    }

    // The default constructor is added if no generative or unnamed factory
    // constructors are declared.
    bool needsSynthesizedDefaultConstructor = true;
    for (MemberBuilder constructorBuilder in nameSpaceBuilder.constructors) {
      if (!constructorBuilder.isFactory || constructorBuilder.name == "") {
        needsSynthesizedDefaultConstructor = false;
        break;
      }
    }
    if (needsSynthesizedDefaultConstructor) {
      synthesizedDefaultConstructorBuilder =
          new DeclaredSourceConstructorBuilder(
              /* metadata = */ null,
              constMask,
              /* returnType = */ libraryBuilder.loader.inferableTypes
                  .addInferableType(),
              /* name = */ "",
              /* typeParameters = */ null,
              /* formals = */ [],
              libraryBuilder,
              fileUri,
              charOffset,
              charOffset,
              charOffset,
              charEndOffset,
              constructorReference,
              tearOffReference,
              new NameScheme(
                  isInstanceMember: false,
                  containerName: new ClassName(name),
                  containerType: ContainerType.Class,
                  libraryName: libraryName),
              forAbstractClassOrEnumOrMixin: true,
              isSynthetic: true);
      synthesizedDefaultConstructorBuilder!
          .registerInitializedField(valuesBuilder);
      nameSpaceBuilder.addConstructor(
          "", synthesizedDefaultConstructorBuilder!);
    }

    ProcedureBuilder toStringBuilder = new SourceProcedureBuilder(
        /* metadata = */ null,
        0,
        stringType,
        "_enumToString",
        /* typeVariables = */ null,
        /* formals = */ null,
        ProcedureKind.Method,
        libraryBuilder,
        fileUri,
        charOffset,
        charOffset,
        charOffset,
        charEndOffset,
        toStringReference,
        /* tearOffReference = */ null,
        AsyncMarker.Sync,
        new NameScheme(
            isInstanceMember: true,
            containerName: new ClassName(name),
            containerType: ContainerType.Class,
            libraryName: new LibraryName(coreLibrary.library.reference)),
        isSynthetic: true);
    nameSpaceBuilder.addLocalMember("_enumToString", toStringBuilder,
        setter: false);
    String className = name;

    if (enumConstantInfos != null) {
      for (int i = 0; i < enumConstantInfos!.length; i++) {
        EnumConstantInfo enumConstantInfo = enumConstantInfos![i]!;
        List<MetadataBuilder>? metadata = enumConstantInfo.metadata;
        String name = enumConstantInfo.name;
        MemberBuilder? existing =
            nameSpaceBuilder.lookupLocalMember(name, setter: false);
        if (existing != null) {
          // The existing declaration is synthetic if it has the same
          // charOffset as the enclosing enum.
          bool isSynthetic = existing.charOffset == charOffset;

          // Report the error on the member that occurs later in the code.
          int existingOffset;
          int duplicateOffset;
          if (existing.charOffset < enumConstantInfo.charOffset) {
            existingOffset = existing.charOffset;
            duplicateOffset = enumConstantInfo.charOffset;
          } else {
            existingOffset = enumConstantInfo.charOffset;
            duplicateOffset = existing.charOffset;
          }

          List<LocatedMessage> context = isSynthetic
              ? <LocatedMessage>[
                  templateDuplicatedDeclarationSyntheticCause
                      .withArguments(name)
                      .withLocation(
                          libraryBuilder.fileUri, charOffset, className.length)
                ]
              : <LocatedMessage>[
                  templateDuplicatedDeclarationCause
                      .withArguments(name)
                      .withLocation(
                          libraryBuilder.fileUri, existingOffset, name.length)
                ];
          libraryBuilder.addProblem(
              templateDuplicatedDeclaration.withArguments(name),
              duplicateOffset,
              name.length,
              libraryBuilder.fileUri,
              context: context);
          enumConstantInfos![i] = null;
        } else if (name == className) {
          libraryBuilder.addProblem(
              templateEnumConstantSameNameAsEnclosing.withArguments(name),
              enumConstantInfo.charOffset,
              name.length,
              libraryBuilder.fileUri);
        }
        Reference? fieldReference;
        Reference? getterReference;
        Reference? setterReference;
        if (indexedClass != null) {
          Name nameName = new Name(name, indexedClass!.library);
          fieldReference = indexedClass!.lookupFieldReference(nameName);
          getterReference = indexedClass!.lookupGetterReference(nameName);
          setterReference = indexedClass!.lookupSetterReference(nameName);
        }
        SourceFieldBuilder fieldBuilder = new SourceFieldBuilder(
            metadata,
            libraryBuilder.loader.inferableTypes.addInferableType(),
            name,
            constMask | staticMask | hasInitializerMask,
            /* isTopLevel = */ false,
            libraryBuilder,
            fileUri,
            enumConstantInfo.charOffset,
            enumConstantInfo.charOffset,
            staticFieldNameScheme,
            fieldReference: fieldReference,
            fieldGetterReference: getterReference,
            fieldSetterReference: setterReference,
            initializerToken: enumConstantInfo.argumentsBeginToken,
            isEnumElement: true);
        nameSpaceBuilder.addLocalMember(name, fieldBuilder..next = existing,
            setter: false);
        elementBuilders.add(fieldBuilder);
      }
    }

    selfType.bind(libraryBuilder, this);

    if (name == "values") {
      libraryBuilder.addProblem(
          messageEnumWithNameValues, this.charOffset, name.length, fileUri);
    }
  }

  @override
  bool get isEnum => true;

  @override
  TypeBuilder? get mixedInTypeBuilder => null;

  NamedTypeBuilder? _computeEnumSupertype() {
    TypeBuilder? supertypeBuilder = this.supertypeBuilder;
    NamedTypeBuilder? enumType;

    while (enumType == null && supertypeBuilder is NamedTypeBuilder) {
      TypeDeclarationBuilder? superclassBuilder = supertypeBuilder.declaration;
      if (superclassBuilder is ClassBuilder &&
          superclassBuilder.isMixinApplication) {
        supertypeBuilder = superclassBuilder.supertypeBuilder;
      } else {
        enumType = supertypeBuilder;
      }
    }
    assert(enumType is NamedTypeBuilder && enumType.typeName.name == "_Enum");
    return enumType;
  }

  @override
  Class build(LibraryBuilder coreLibrary) {
    intType.resolveIn(coreLibrary.scope, charOffset, fileUri, libraryBuilder);
    stringType.resolveIn(
        coreLibrary.scope, charOffset, fileUri, libraryBuilder);
    objectType.resolveIn(
        coreLibrary.scope, charOffset, fileUri, libraryBuilder);
    NamedTypeBuilder? enumType = _computeEnumSupertype();
    enumType!.resolveIn(coreLibrary.scope, charOffset, fileUri, libraryBuilder);

    listType.resolveIn(coreLibrary.scope, charOffset, fileUri, libraryBuilder);

    Class cls = super.build(coreLibrary);
    cls.isEnum = true;

    // The super initializer for the synthesized default constructor is
    // inserted here if the enum's supertype is _Enum to preserve the legacy
    // behavior or having the old-style enum constants built in the outlines.
    // Other constructors are handled in [BodyBuilder.finishConstructor] as
    // they are processed via the pipeline for constructor parsing and
    // building.
    if (identical(this.supertypeBuilder, enumType)) {
      if (synthesizedDefaultConstructorBuilder != null) {
        Constructor constructor =
            synthesizedDefaultConstructorBuilder!.constructor;
        ClassBuilder objectClass = objectType.declaration as ClassBuilder;
        ClassBuilder enumClass = enumType.declaration as ClassBuilder;
        MemberBuilder? superConstructor = enumClass.findConstructorOrFactory(
            "", charOffset, fileUri, libraryBuilder);
        if (superConstructor == null || !superConstructor.isConstructor) {
          // Coverage-ignore-block(suite): Not run.
          // TODO(ahe): Ideally, we would also want to check that [Object]'s
          // unnamed constructor requires no arguments. But that information
          // isn't always available at this point, and it's not really a
          // situation that can happen unless you start modifying the SDK
          // sources. (We should add a correct message. We no longer depend on
          // Object here.)
          libraryBuilder.addProblem(
              messageNoUnnamedConstructorInObject,
              objectClass.charOffset,
              objectClass.name.length,
              objectClass.fileUri);
        } else {
          constructor.initializers.add(new SuperInitializer(
              superConstructor.member as Constructor,
              new Arguments.forwarded(
                  constructor.function, libraryBuilder.library))
            ..parent = constructor);
        }
        synthesizedDefaultConstructorBuilder = null;
      }
    }

    return cls;
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
      {required bool inOutlineBuildingPhase,
      required bool inMetadata,
      required bool inConstFields}) {
    return new EnumBodyBuilderContext(this,
        inOutlineBuildingPhase: inOutlineBuildingPhase,
        inMetadata: inMetadata,
        inConstFields: inConstFields);
  }

  DartType buildElement(SourceFieldBuilder fieldBuilder, CoreTypes coreTypes) {
    DartType selfType =
        this.selfType.build(libraryBuilder, TypeUse.enumSelfType);
    if (!_builtElements.add(fieldBuilder)) return fieldBuilder.fieldType;

    if (enumConstantInfos == null) return selfType;

    String constant = fieldBuilder.name;

    EnumConstantInfo? enumConstantInfo;
    int elementIndex = 0;
    for (EnumConstantInfo? info in enumConstantInfos!) {
      if (info?.name == constant) {
        enumConstantInfo = info;
        break;
      }
      // Skip the duplicated entries in numbering.
      if (info?.name != null) {
        elementIndex++;
      }
    }
    if (enumConstantInfo == null) return selfType;

    DartType inferredFieldType = selfType;

    String constructorName =
        enumConstantInfo.constructorReferenceBuilder?.suffix ?? "";
    String fullConstructorNameForErrors =
        enumConstantInfo.constructorReferenceBuilder?.fullNameForErrors ?? name;
    int fileOffset = enumConstantInfo.constructorReferenceBuilder?.charOffset ??
        enumConstantInfo.charOffset;
    constructorName = constructorName == "new" ? "" : constructorName;
    MemberBuilder? constructorBuilder =
        nameSpace.lookupConstructor(constructorName);

    ArgumentsImpl arguments;
    List<Expression> enumSyntheticArguments = <Expression>[
      new IntLiteral(elementIndex),
      new StringLiteral(constant),
    ];
    List<DartType>? typeArguments;
    List<TypeBuilder>? typeArgumentBuilders =
        enumConstantInfo.constructorReferenceBuilder?.typeArguments;
    if (typeArgumentBuilders != null) {
      typeArguments = <DartType>[];
      for (TypeBuilder typeBuilder in typeArgumentBuilders) {
        typeArguments.add(
            typeBuilder.build(libraryBuilder, TypeUse.constructorTypeArgument));
      }
    }
    if (libraryBuilder.libraryFeatures.enhancedEnums.isEnabled) {
      // We need to create a BodyBuilder to solve the following: 1) if
      // the arguments token is provided, we'll use the BodyBuilder to
      // parse them and perform inference, 2) if the type arguments
      // aren't provided, but required, we'll use it to infer them, and
      // 3) in case of erroneous code the constructor invocation should
      // be built via a body builder to detect potential errors.
      BodyBuilder bodyBuilder = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(
              libraryBuilder,
              createBodyBuilderContext(
                  inOutlineBuildingPhase: true,
                  inMetadata: false,
                  inConstFields: false),
              scope,
              fileUri);
      bodyBuilder.constantContext = ConstantContext.inferred;

      if (enumConstantInfo.argumentsBeginToken != null) {
        arguments =
            bodyBuilder.parseArguments(enumConstantInfo.argumentsBeginToken!);
        // We pass `true` for [allowFurtherDelays] here because the members of
        // the enums are built before the inference, and the resolution of the
        // redirecting factories can't be completed at this moment and
        // therefore should be delayed to another invocation of
        // [BodyBuilder.performBacklogComputations].
        bodyBuilder.performBacklogComputations();

        arguments.positional.insertAll(0, enumSyntheticArguments);
        arguments.argumentsOriginalOrder?.insertAll(0, enumSyntheticArguments);
        enumConstantInfo.argumentsBeginToken = null;
      } else {
        arguments = new ArgumentsImpl(enumSyntheticArguments);
      }
      if (typeArguments != null) {
        ArgumentsImpl.setNonInferrableArgumentTypes(arguments, typeArguments);
      } else if (cls.typeParameters.isNotEmpty) {
        arguments.types.addAll(new List<DartType>.filled(
            cls.typeParameters.length, const UnknownType()));
      }
      setParents(enumSyntheticArguments, arguments);
      if (constructorBuilder == null ||
          constructorBuilder is! SourceConstructorBuilder) {
        if (!fieldBuilder.hasBodyBeenBuilt) {
          fieldBuilder.buildBody(
              coreTypes,
              bodyBuilder.buildUnresolvedError(
                  fullConstructorNameForErrors, fileOffset,
                  arguments: arguments, kind: UnresolvedKind.Constructor));
        }
      } else {
        Expression initializer = bodyBuilder.buildStaticInvocation(
            constructorBuilder.invokeTarget, arguments,
            constness: Constness.explicitConst,
            charOffset: fieldBuilder.charOffset,
            isConstructorInvocation: true);
        ExpressionInferenceResult inferenceResult = bodyBuilder.typeInferrer
            .inferFieldInitializer(
                bodyBuilder, const UnknownType(), initializer);
        initializer = inferenceResult.expression;
        inferredFieldType = inferenceResult.inferredType;
        if (!fieldBuilder.hasBodyBeenBuilt) {
          fieldBuilder.buildBody(coreTypes, initializer);
        }
      }
    } else {
      arguments = new ArgumentsImpl(enumSyntheticArguments);
      setParents(enumSyntheticArguments, arguments);
      if (constructorBuilder == null ||
          constructorBuilder is! SourceConstructorBuilder ||
          !constructorBuilder.isConst) {
        // This can only occur if there enhanced enum features are used
        // when they are not enabled.
        assert(libraryBuilder.loader.hasSeenError);
        String text = libraryBuilder.loader.target.context
            .format(
                templateConstructorNotFound
                    .withArguments(fullConstructorNameForErrors)
                    .withLocation(fieldBuilder.fileUri, fileOffset, noLength),
                Severity.error)
            .plain;
        if (!fieldBuilder.hasBodyBeenBuilt) {
          fieldBuilder.buildBody(
              coreTypes, new InvalidExpression(text)..fileOffset = charOffset);
        }
      } else {
        Expression initializer = new ConstructorInvocation(
            constructorBuilder.invokeTarget as Constructor, arguments,
            isConst: true)
          ..fileOffset = fieldBuilder.charOffset;
        if (!fieldBuilder.hasBodyBeenBuilt) {
          fieldBuilder.buildBody(coreTypes, initializer);
        }
      }
    }

    return inferredFieldType;
  }

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    List<Expression> values = <Expression>[];
    if (enumConstantInfos != null) {
      for (EnumConstantInfo? enumConstantInfo in enumConstantInfos!) {
        if (enumConstantInfo != null) {
          Builder declaration = firstMemberNamed(enumConstantInfo.name)!;
          if (declaration.isField) {
            SourceFieldBuilder fieldBuilder = declaration as SourceFieldBuilder;
            values.add(new StaticGet(fieldBuilder.field));
          }
        }
      }
    }
    SourceFieldBuilder valuesBuilder =
        firstMemberNamed("values") as SourceFieldBuilder;
    valuesBuilder.buildBody(
        classHierarchy.coreTypes,
        new ListLiteral(values,
            typeArgument: instantiateToBounds(rawType(Nullability.nonNullable),
                classHierarchy.coreTypes.objectClass),
            isConst: true));

    for (SourceFieldBuilder elementBuilder in elementBuilders) {
      elementBuilder.type.registerInferredType(
          buildElement(elementBuilder, classHierarchy.coreTypes));
    }

    SourceProcedureBuilder toStringBuilder =
        firstMemberNamed("_enumToString") as SourceProcedureBuilder;

    Name toStringName =
        new Name("_enumToString", classHierarchy.coreTypes.coreLibrary);
    Member? superToString = cls.superclass != null
        ? classHierarchy.getDispatchTarget(cls.superclass!, toStringName)
        : null;
    Procedure? toStringSuperTarget = superToString is Procedure &&
            // Coverage-ignore(suite): Not run.
            superToString.enclosingClass != classHierarchy.coreTypes.objectClass
        ? superToString
        : null;

    if (toStringSuperTarget != null) {
      // Coverage-ignore-block(suite): Not run.
      toStringBuilder.member.transformerFlags |= TransformerFlag.superCalls;
      toStringBuilder.body = new ReturnStatement(new SuperMethodInvocation(
          toStringName, new Arguments([]), toStringSuperTarget));
    } else {
      ClassBuilder enumClass =
          _computeEnumSupertype()!.declaration as ClassBuilder;
      MemberBuilder? nameFieldBuilder =
          enumClass.lookupLocalMember("_name") as MemberBuilder?;
      assert(nameFieldBuilder != null);
      Field nameField = nameFieldBuilder!.member as Field;

      toStringBuilder.body = new ReturnStatement(new StringConcatenation([
        new StringLiteral("${cls.demangledName}."),
        new InstanceGet.byReference(
            InstanceAccessKind.Instance, new ThisExpression(), nameField.name,
            interfaceTargetReference: nameField.getterReference,
            resultType: nameField.getterType),
      ]));
    }

    super.buildOutlineExpressions(classHierarchy, delayedDefaultValueCloners);
  }
}

class EnumConstantInfo {
  final List<MetadataBuilder>? metadata;
  final String name;
  final int charOffset;
  ConstructorReferenceBuilder? constructorReferenceBuilder;
  Token? argumentsBeginToken;

  EnumConstantInfo(this.metadata, this.name, this.charOffset);
}
