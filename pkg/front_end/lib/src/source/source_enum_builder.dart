// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/reference_from_index.dart' show IndexedClass;
import 'package:kernel/src/bounds_checks.dart';
import 'package:kernel/transformations/flags.dart';

import '../base/constant_context.dart';
import '../base/modifiers.dart' show Modifiers;
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
  final int startOffset;
  final int endOffset;

  final List<EnumConstantInfo?>? enumConstantInfos;

  final TypeBuilder _underscoreEnumTypeBuilder;

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
      {required List<MetadataBuilder>? metadata,
      required String name,
      required List<NominalParameterBuilder>? typeParameters,
      required TypeBuilder underscoreEnumTypeBuilder,
      required TypeBuilder supertypeBuilder,
      required List<TypeBuilder>? interfaceBuilders,
      required LookupScope typeParameterScope,
      required DeclarationNameSpaceBuilder nameSpaceBuilder,
      required this.enumConstantInfos,
      required SourceLibraryBuilder libraryBuilder,
      required List<ConstructorReferenceBuilder> constructorReferences,
      required Uri fileUri,
      required this.startOffset,
      required int nameOffset,
      required this.endOffset,
      required IndexedClass? indexedClass})
      : _underscoreEnumTypeBuilder = underscoreEnumTypeBuilder,
        super(
            metadata: metadata,
            modifiers: Modifiers.empty,
            name: name,
            typeParameters: typeParameters,
            supertypeBuilder: supertypeBuilder,
            interfaceBuilders: interfaceBuilders,
            onTypes: null,
            typeParameterScope: typeParameterScope,
            nameSpaceBuilder: nameSpaceBuilder,
            libraryBuilder: libraryBuilder,
            constructorReferences: constructorReferences,
            fileUri: fileUri,
            startOffset: startOffset,
            nameOffset: nameOffset,
            endOffset: endOffset,
            indexedClass: indexedClass);

  factory SourceEnumBuilder(
      {required List<MetadataBuilder>? metadata,
      required String name,
      required List<NominalParameterBuilder>? typeParameters,
      required TypeBuilder underscoreEnumTypeBuilder,
      required TypeBuilder? supertypeBuilder,
      required List<TypeBuilder>? interfaceBuilders,
      required List<EnumConstantInfo?>? enumConstantInfos,
      required SourceLibraryBuilder libraryBuilder,
      required List<ConstructorReferenceBuilder> constructorReferences,
      required Uri fileUri,
      required int startOffset,
      required int nameOffset,
      required int endOffset,
      required IndexedClass? indexedClass,
      required LookupScope typeParameterScope,
      required DeclarationNameSpaceBuilder nameSpaceBuilder}) {
    supertypeBuilder ??= underscoreEnumTypeBuilder;
    SourceEnumBuilder enumBuilder = new SourceEnumBuilder.internal(
        metadata: metadata,
        name: name,
        typeParameters: typeParameters,
        underscoreEnumTypeBuilder: underscoreEnumTypeBuilder,
        supertypeBuilder: supertypeBuilder,
        interfaceBuilders: interfaceBuilders,
        typeParameterScope: typeParameterScope,
        nameSpaceBuilder: nameSpaceBuilder,
        enumConstantInfos: enumConstantInfos,
        libraryBuilder: libraryBuilder,
        constructorReferences: constructorReferences,
        fileUri: fileUri,
        startOffset: startOffset,
        nameOffset: nameOffset,
        endOffset: endOffset,
        indexedClass: indexedClass);
    return enumBuilder;
  }

  @override
  void buildScopes(LibraryBuilder coreLibrary) {
    super.buildScopes(coreLibrary);
    _createSynthesizedMembers(coreLibrary);

    // Include duplicates to install the formals on all constructors to avoid a
    // crash later.
    Iterator<MemberBuilder> iterator =
        nameSpace.filteredConstructorNameIterator(
            includeDuplicates: true, includeAugmentations: true);
    while (iterator.moveNext()) {
      MemberBuilder member = iterator.current;
      if (member is DeclaredSourceConstructorBuilder) {
        member.ensureGrowableFormals();

        FormalParameterBuilder nameFormalParameterBuilder =
            new FormalParameterBuilder(FormalParameterKind.requiredPositional,
                Modifiers.empty, stringType, "#name", fileOffset,
                fileUri: fileUri, hasImmediatelyDeclaredInitializer: false);
        member.formals!.insert(0, nameFormalParameterBuilder);

        FormalParameterBuilder indexFormalParameterBuilder =
            new FormalParameterBuilder(FormalParameterKind.requiredPositional,
                Modifiers.empty, intType, "#index", fileOffset,
                fileUri: fileUri, hasImmediatelyDeclaredInitializer: false);
        member.formals!.insert(0, indexFormalParameterBuilder);
      }
    }

    Iterator<MemberBuilder> constructorIterator =
        nameSpace.filteredConstructorIterator(
            includeDuplicates: false, includeAugmentations: true);
    while (constructorIterator.moveNext()) {
      MemberBuilder constructorBuilder = constructorIterator.current;
      if (!constructorBuilder.isFactory && !constructorBuilder.isConst) {
        libraryBuilder.addProblem(messageEnumNonConstConstructor,
            constructorBuilder.fileOffset, noLength, fileUri);
      }
    }
  }

  void _createSynthesizedMembers(LibraryBuilder coreLibrary) {
    assert(enumConstantInfos == null || enumConstantInfos!.isNotEmpty);

    // TODO(ahe): These types shouldn't be looked up in scope, they come
    // directly from dart:core.
    intType = new NamedTypeBuilderImpl(
        const PredefinedTypeName("int"), const NullabilityBuilder.omitted(),
        instanceTypeParameterAccess:
            // If "int" resolves to an instance type parameter then that we
            // would allowed (the types that we are adding are in instance
            // context after all) but it would be unexpected and we would like
            // an assertion failure, since "int" was meant to be `int` from
            // `dart:core`.
            // TODO(johnniwinther): Add a more robust way of creating named
            // typed builders for dart:core types. This might be needed for the
            // enhanced enums feature where enums can actually declare type
            // variables.
            InstanceTypeParameterAccessState.Unexpected);
    stringType = new NamedTypeBuilderImpl(
        const PredefinedTypeName("String"), const NullabilityBuilder.omitted(),
        instanceTypeParameterAccess:
            InstanceTypeParameterAccessState.Unexpected);
    objectType = new NamedTypeBuilderImpl(
        const PredefinedTypeName("Object"), const NullabilityBuilder.omitted(),
        instanceTypeParameterAccess:
            InstanceTypeParameterAccessState.Unexpected);
    selfType = new NamedTypeBuilderImpl(new SyntheticTypeName(name, fileOffset),
        const NullabilityBuilder.omitted(),
        instanceTypeParameterAccess:
            InstanceTypeParameterAccessState.Unexpected,
        fileUri: fileUri,
        charOffset: fileOffset);
    listType = new NamedTypeBuilderImpl(
        const PredefinedTypeName("List"), const NullabilityBuilder.omitted(),
        arguments: <TypeBuilder>[selfType],
        instanceTypeParameterAccess:
            InstanceTypeParameterAccessState.Unexpected);

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
        nameSpace.lookupLocalMember("values", setter: false);
    if (customValuesDeclaration != null) {
      // Retrieve the earliest declaration for error reporting.
      while (customValuesDeclaration?.next != null) {
        customValuesDeclaration = customValuesDeclaration?.next;
      }
      libraryBuilder.addProblem(
          messageEnumContainsValuesDeclaration,
          customValuesDeclaration!.fileOffset,
          customValuesDeclaration.fullNameForErrors.length,
          fileUri);
    }

    for (String restrictedInstanceMemberName in const [
      "index",
      "hashCode",
      "=="
    ]) {
      Builder? customIndexDeclaration = nameSpace
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
            customIndexDeclaration!.fileOffset,
            customIndexDeclaration.fullNameForErrors.length,
            fileUri);
      }
    }

    SourceFieldBuilder valuesBuilder = new SourceFieldBuilder(
        metadata: null,
        type: listType,
        name: "values",
        modifiers:
            Modifiers.Const | Modifiers.Static | Modifiers.HasInitializer,
        isTopLevel: false,
        isPrimaryConstructorField: false,
        libraryBuilder: libraryBuilder,
        declarationBuilder: this,
        fileUri: fileUri,
        nameOffset: fileOffset,
        endOffset: fileOffset,
        nameScheme: staticFieldNameScheme,
        fieldReference: valuesFieldReference,
        fieldGetterReference: valuesGetterReference,
        fieldSetterReference: valuesSetterReference,
        isSynthesized: true);
    if (customValuesDeclaration != null) {
      customValuesDeclaration.next = valuesBuilder;
      nameSpaceBuilder.checkTypeParameterConflict(libraryBuilder,
          valuesBuilder.name, valuesBuilder, valuesBuilder.fileUri);
    } else {
      nameSpace.addLocalMember("values", valuesBuilder, setter: false);
      nameSpaceBuilder.checkTypeParameterConflict(libraryBuilder,
          valuesBuilder.name, valuesBuilder, valuesBuilder.fileUri);
    }

    // The default constructor is added if no generative or unnamed factory
    // constructors are declared.
    bool needsSynthesizedDefaultConstructor = true;
    Iterator<MemberBuilder> iterator = nameSpace.unfilteredConstructorIterator;
    while (iterator.moveNext()) {
      MemberBuilder constructorBuilder = iterator.current;
      if (!constructorBuilder.isFactory || constructorBuilder.name == "") {
        needsSynthesizedDefaultConstructor = false;
        break;
      }
    }
    if (needsSynthesizedDefaultConstructor) {
      synthesizedDefaultConstructorBuilder =
          new DeclaredSourceConstructorBuilder(
              metadata: null,
              modifiers: Modifiers.Const,
              returnType:
                  libraryBuilder.loader.inferableTypes.addInferableType(),
              name: "",
              typeParameters: null,
              formals: [],
              libraryBuilder: libraryBuilder,
              declarationBuilder: this,
              fileUri: fileUri,
              startOffset: fileOffset,
              fileOffset: fileOffset,
              formalsOffset: fileOffset,
              endOffset: endOffset,
              constructorReference: constructorReference,
              tearOffReference: tearOffReference,
              nameScheme: new NameScheme(
                  isInstanceMember: false,
                  containerName: new ClassName(name),
                  containerType: ContainerType.Class,
                  libraryName: libraryName),
              forAbstractClassOrEnumOrMixin: true,
              isSynthetic: true,
              // Trick the constructor to be built during the outline phase.
              // TODO(johnniwinther): Avoid relying on [beginInitializers] to
              // ensure building constructors creation during the outline phase.
              beginInitializers: new Token.eof(-1));
      synthesizedDefaultConstructorBuilder!
          .registerInitializedField(valuesBuilder);
      nameSpace.addConstructor("", synthesizedDefaultConstructorBuilder!);
      nameSpaceBuilder.checkTypeParameterConflict(
          libraryBuilder,
          synthesizedDefaultConstructorBuilder!.name,
          synthesizedDefaultConstructorBuilder!,
          synthesizedDefaultConstructorBuilder!.fileUri);
    }

    ProcedureBuilder toStringBuilder = new SourceProcedureBuilder(
        metadata: null,
        modifiers: Modifiers.empty,
        returnType: stringType,
        name: "_enumToString",
        typeParameters: null,
        formals: null,
        kind: ProcedureKind.Method,
        libraryBuilder: libraryBuilder,
        declarationBuilder: this,
        fileUri: fileUri,
        startOffset: fileOffset,
        nameOffset: fileOffset,
        formalsOffset: fileOffset,
        endOffset: endOffset,
        procedureReference: toStringReference,
        tearOffReference: null,
        asyncModifier: AsyncMarker.Sync,
        nameScheme: new NameScheme(
            isInstanceMember: true,
            containerName: new ClassName(name),
            containerType: ContainerType.Class,
            libraryName: new LibraryName(coreLibrary.library.reference)),
        isSynthetic: true);
    nameSpace.addLocalMember("_enumToString", toStringBuilder, setter: false);
    nameSpaceBuilder.checkTypeParameterConflict(libraryBuilder,
        toStringBuilder.name, toStringBuilder, toStringBuilder.fileUri!);

    String className = name;

    if (enumConstantInfos != null) {
      for (int i = 0; i < enumConstantInfos!.length; i++) {
        EnumConstantInfo enumConstantInfo = enumConstantInfos![i]!;
        List<MetadataBuilder>? metadata = enumConstantInfo.metadata;
        String name = enumConstantInfo.name;
        MemberBuilder? existing =
            nameSpace.lookupLocalMember(name, setter: false) as MemberBuilder?;
        if (existing != null) {
          // The existing declaration is synthetic if it has the same
          // charOffset as the enclosing enum.
          bool isSynthetic = existing.fileOffset == fileOffset;

          // Report the error on the member that occurs later in the code.
          int existingOffset;
          int duplicateOffset;
          if (existing.fileOffset < enumConstantInfo.nameOffset) {
            existingOffset = existing.fileOffset;
            duplicateOffset = enumConstantInfo.nameOffset;
          } else {
            existingOffset = enumConstantInfo.nameOffset;
            duplicateOffset = existing.fileOffset;
          }

          List<LocatedMessage> context = isSynthetic
              ? <LocatedMessage>[
                  templateDuplicatedDeclarationSyntheticCause
                      .withArguments(name)
                      .withLocation(
                          libraryBuilder.fileUri, fileOffset, className.length)
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
              enumConstantInfo.nameOffset,
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
            metadata: metadata,
            type: libraryBuilder.loader.inferableTypes.addInferableType(),
            name: name,
            modifiers:
                Modifiers.Const | Modifiers.Static | Modifiers.HasInitializer,
            isTopLevel: false,
            isPrimaryConstructorField: false,
            libraryBuilder: libraryBuilder,
            declarationBuilder: this,
            fileUri: fileUri,
            nameOffset: enumConstantInfo.nameOffset,
            endOffset: enumConstantInfo.nameOffset,
            nameScheme: staticFieldNameScheme,
            fieldReference: fieldReference,
            fieldGetterReference: getterReference,
            fieldSetterReference: setterReference,
            initializerToken: enumConstantInfo.argumentsBeginToken,
            isEnumElement: true);
        nameSpace.addLocalMember(name, fieldBuilder..next = existing,
            setter: false);
        nameSpaceBuilder.checkTypeParameterConflict(libraryBuilder,
            fieldBuilder.name, fieldBuilder, fieldBuilder.fileUri);
        elementBuilders.add(fieldBuilder);
      }
    }

    selfType.bind(libraryBuilder, this);

    if (name == "values") {
      libraryBuilder.addProblem(
          messageEnumWithNameValues, this.fileOffset, name.length, fileUri);
    }
  }

  @override
  bool get isEnum => true;

  @override
  TypeBuilder? get mixedInTypeBuilder => null;

  @override
  Class build(LibraryBuilder coreLibrary) {
    intType.resolveIn(coreLibrary.scope, fileOffset, fileUri, libraryBuilder);
    stringType.resolveIn(
        coreLibrary.scope, fileOffset, fileUri, libraryBuilder);
    objectType.resolveIn(
        coreLibrary.scope, fileOffset, fileUri, libraryBuilder);
    listType.resolveIn(coreLibrary.scope, fileOffset, fileUri, libraryBuilder);

    Class cls = super.build(coreLibrary);
    cls.isEnum = true;

    // The super initializer for the synthesized default constructor is
    // inserted here if the enum's supertype is _Enum to preserve the legacy
    // behavior or having the old-style enum constants built in the outlines.
    // Other constructors are handled in [BodyBuilder.finishConstructor] as
    // they are processed via the pipeline for constructor parsing and
    // building.
    if (identical(this.supertypeBuilder, _underscoreEnumTypeBuilder)) {
      if (synthesizedDefaultConstructorBuilder != null) {
        Constructor constructor =
            synthesizedDefaultConstructorBuilder!.constructor;
        ClassBuilder objectClass = objectType.declaration as ClassBuilder;
        ClassBuilder enumClass =
            _underscoreEnumTypeBuilder.declaration as ClassBuilder;
        MemberBuilder? superConstructor = enumClass.findConstructorOrFactory(
            "", fileOffset, fileUri, libraryBuilder);
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
              objectClass.fileOffset,
              objectClass.name.length,
              objectClass.fileUri);
        } else {
          constructor.initializers.add(new SuperInitializer(
              superConstructor.invokeTarget as Constructor,
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
  BodyBuilderContext createBodyBuilderContext() {
    return new EnumBodyBuilderContext(this);
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
        enumConstantInfo.nameOffset;
    constructorName = constructorName == "new" ? "" : constructorName;
    MemberBuilder? constructorBuilder =
        nameSpace.lookupConstructor(constructorName);
    // TODO(CFE Team): Should there be a conversion to an invalid expression
    // instead? That's what happens on classes.
    while (constructorBuilder?.next != null) {
      constructorBuilder = constructorBuilder?.next as MemberBuilder;
    }

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
              libraryBuilder, createBodyBuilderContext(), scope, fileUri);
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
            charOffset: fieldBuilder.fileOffset,
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
          fieldBuilder.buildBody(coreTypes,
              new InvalidExpression(text)..fileOffset = this.fileOffset);
        }
      } else {
        Expression initializer = new ConstructorInvocation(
            constructorBuilder.invokeTarget as Constructor, arguments,
            isConst: true)
          ..fileOffset = fieldBuilder.fileOffset;
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
      toStringBuilder.invokeTarget!.transformerFlags |=
          TransformerFlag.superCalls;
      toStringBuilder.body = new ReturnStatement(new SuperMethodInvocation(
          toStringName, new Arguments([]), toStringSuperTarget));
    } else {
      ClassBuilder enumClass =
          _underscoreEnumTypeBuilder.declaration as ClassBuilder;
      MemberBuilder? nameFieldBuilder =
          enumClass.lookupLocalMember("_name") as MemberBuilder?;
      assert(nameFieldBuilder != null);
      Field nameField = nameFieldBuilder!.readTarget as Field;

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
  final int nameOffset;
  ConstructorReferenceBuilder? constructorReferenceBuilder;
  Token? argumentsBeginToken;

  EnumConstantInfo(this.metadata, this.name, this.nameOffset);
}
