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
import '../fasta_codes.dart'
    show
        LocatedMessage,
        Severity,
        messageConflictsWithTypeVariableCause,
        messageEnumContainsValuesDeclaration,
        messageEnumNonConstConstructor,
        messageEnumWithNameValues,
        messageNoUnnamedConstructorInObject,
        noLength,
        templateConflictsWithTypeVariable,
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
import '../kernel/kernel_helper.dart';
import '../kernel/internal_ast.dart';

import '../modifier.dart' show constMask, hasInitializerMask, staticMask;

import '../constant_context.dart';
import '../scope.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/type_schema.dart';
import '../util/helpers.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart' show SourceClassBuilder;
import 'source_constructor_builder.dart';
import 'source_field_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_procedure_builder.dart';

class SourceEnumBuilder extends SourceClassBuilder {
  final List<EnumConstantInfo?>? enumConstantInfos;

  final NamedTypeBuilder intType;

  final NamedTypeBuilder stringType;

  final NamedTypeBuilder objectType;

  final NamedTypeBuilder listType;

  final NamedTypeBuilder selfType;

  DeclaredSourceConstructorBuilder? synthesizedDefaultConstructorBuilder;

  final List<SourceFieldBuilder> elementBuilders;

  final Set<SourceFieldBuilder> _builtElements =
      new Set<SourceFieldBuilder>.identity();

  final List<DelayedActionPerformer> _delayedActionPerformers = [];

  SourceEnumBuilder.internal(
      List<MetadataBuilder>? metadata,
      String name,
      List<TypeVariableBuilder>? typeVariables,
      TypeBuilder supertypeBuilder,
      List<TypeBuilder>? interfaceBuilders,
      Scope scope,
      ConstructorScope constructors,
      Class cls,
      this.elementBuilders,
      this.enumConstantInfos,
      this.intType,
      this.listType,
      this.objectType,
      this.stringType,
      this.selfType,
      SourceLibraryBuilder parent,
      List<ConstructorReferenceBuilder> constructorReferences,
      int startCharOffset,
      int charOffset,
      int charEndOffset,
      IndexedClass? referencesFromIndexed)
      : super(
            metadata,
            0,
            name,
            typeVariables,
            supertypeBuilder,
            interfaceBuilders,
            /* onTypes = */ null,
            scope,
            constructors,
            parent,
            constructorReferences,
            startCharOffset,
            charOffset,
            charEndOffset,
            referencesFromIndexed,
            cls: cls);

  factory SourceEnumBuilder(
      List<MetadataBuilder>? metadata,
      String name,
      List<TypeVariableBuilder>? typeVariables,
      TypeBuilder? supertypeBuilder,
      List<TypeBuilder>? interfaceBuilders,
      List<EnumConstantInfo?>? enumConstantInfos,
      SourceLibraryBuilder libraryBuilder,
      List<ConstructorReferenceBuilder> constructorReferences,
      int startCharOffset,
      int charOffset,
      int charEndOffset,
      IndexedClass? referencesFromIndexed,
      Scope scope,
      ConstructorScope constructorScope,
      LibraryBuilder coreLibrary) {
    assert(enumConstantInfos == null || enumConstantInfos.isNotEmpty);

    Uri fileUri = libraryBuilder.fileUri;

    // TODO(ahe): These types shouldn't be looked up in scope, they come
    // directly from dart:core.
    NamedTypeBuilder intType = new NamedTypeBuilderImpl(
        "int", const NullabilityBuilder.omitted(),
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
    NamedTypeBuilder stringType = new NamedTypeBuilderImpl(
        "String", const NullabilityBuilder.omitted(),
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);
    NamedTypeBuilder objectType = new NamedTypeBuilderImpl(
        "Object", const NullabilityBuilder.omitted(),
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);
    supertypeBuilder ??= new NamedTypeBuilderImpl(
        "_Enum", const NullabilityBuilder.omitted(),
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected);
    Class cls = new Class(
        name: name,
        typeParameters:
            TypeVariableBuilder.typeParametersFromBuilders(typeVariables),
        reference: referencesFromIndexed?.cls.reference,
        fileUri: fileUri);
    Map<String, MemberBuilder> members = <String, MemberBuilder>{};
    Map<String, MemberBuilder> setters = <String, MemberBuilder>{};
    Map<String, MemberBuilder> constructors = <String, MemberBuilder>{};
    List<SourceFieldBuilder> elementBuilders = <SourceFieldBuilder>[];
    NamedTypeBuilder selfType = new NamedTypeBuilderImpl(
        name, const NullabilityBuilder.omitted(),
        instanceTypeVariableAccess: InstanceTypeVariableAccessState.Unexpected,
        fileUri: fileUri,
        charOffset: charOffset);
    NamedTypeBuilder listType = new NamedTypeBuilderImpl(
        "List", const NullabilityBuilder.omitted(),
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

    LibraryName libraryName = referencesFromIndexed != null
        ? new LibraryName(referencesFromIndexed.library.reference)
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
    if (referencesFromIndexed != null) {
      constructorReference =
          referencesFromIndexed.lookupConstructorReference(new Name(""));
      tearOffReference = referencesFromIndexed.lookupGetterReference(
          new Name(constructorTearOffName(""), referencesFromIndexed.library));
      toStringReference = referencesFromIndexed.lookupGetterReference(
          new Name("_enumToString", coreLibrary.library));
      Name valuesName = new Name("values");
      valuesFieldReference =
          referencesFromIndexed.lookupFieldReference(valuesName);
      valuesGetterReference =
          referencesFromIndexed.lookupGetterReference(valuesName);
      valuesSetterReference =
          referencesFromIndexed.lookupSetterReference(valuesName);
    }

    Builder? customValuesDeclaration =
        scope.lookupLocalMember("values", setter: false);
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
      Builder? customIndexDeclaration =
          scope.lookupLocalMember(restrictedInstanceMemberName, setter: false);
      if (customIndexDeclaration is MemberBuilder &&
          !customIndexDeclaration.isAbstract) {
        // Retrieve the earliest declaration for error reporting.
        while (customIndexDeclaration?.next != null) {
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
      members["values"] = valuesBuilder;
    }

    DeclaredSourceConstructorBuilder? synthesizedDefaultConstructorBuilder;

    // The default constructor is added if no generative or unnamed factory
    // constructors are declared.
    bool needsSynthesizedDefaultConstructor = true;
    Iterator<MemberBuilder> iterator = constructorScope.filteredIterator(
        includeDuplicates: false, includeAugmentations: true);
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
              /* metadata = */ null,
              constMask,
              /* returnType = */ libraryBuilder.addInferableType(),
              "",
              /* typeParameters = */ null,
              <FormalParameterBuilder>[
                new FormalParameterBuilder(
                    null,
                    FormalParameterKind.requiredPositional,
                    0,
                    intType,
                    "#index",
                    libraryBuilder,
                    charOffset,
                    hasImmediatelyDeclaredInitializer: false),
                new FormalParameterBuilder(
                    null,
                    FormalParameterKind.requiredPositional,
                    0,
                    stringType,
                    "#name",
                    libraryBuilder,
                    charOffset,
                    hasImmediatelyDeclaredInitializer: false)
              ],
              libraryBuilder,
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
              forAbstractClassOrEnumOrMixin: true);
      synthesizedDefaultConstructorBuilder
          .registerInitializedField(valuesBuilder);
      constructors[""] = synthesizedDefaultConstructorBuilder;
    } else {
      Iterator<MemberBuilder> iterator = constructorScope.filteredNameIterator(
          includeDuplicates: false, includeAugmentations: true);
      while (iterator.moveNext()) {
        MemberBuilder member = iterator.current;
        if (member is DeclaredSourceConstructorBuilder) {
          member.ensureGrowableFormals();
          member.formals!.insert(
              0,
              new FormalParameterBuilder(
                  /* metadata = */ null,
                  FormalParameterKind.requiredPositional,
                  /* modifiers = */ 0,
                  stringType,
                  "#name",
                  libraryBuilder,
                  charOffset,
                  hasImmediatelyDeclaredInitializer: false));
          member.formals!.insert(
              0,
              new FormalParameterBuilder(
                  /* metadata = */ null,
                  FormalParameterKind.requiredPositional,
                  /* modifiers = */ 0,
                  intType,
                  "#index",
                  libraryBuilder,
                  charOffset,
                  hasImmediatelyDeclaredInitializer: false));
        }
      }
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
    members["_enumToString"] = toStringBuilder;
    String className = name;
    final int startCharOffsetComputed =
        metadata == null ? startCharOffset : metadata.first.charOffset;
    scope.forEachLocalMember((name, member) {
      members[name] = member as MemberBuilder;
    });
    scope.forEachLocalSetter((name, member) {
      setters[name] = member;
    });

    if (enumConstantInfos != null) {
      for (int i = 0; i < enumConstantInfos.length; i++) {
        EnumConstantInfo enumConstantInfo = enumConstantInfos[i]!;
        List<MetadataBuilder>? metadata = enumConstantInfo.metadata;
        String name = enumConstantInfo.name;
        MemberBuilder? existing = members[name];
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
          enumConstantInfos[i] = null;
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
        if (referencesFromIndexed != null) {
          Name nameName = new Name(name, referencesFromIndexed.library);
          fieldReference = referencesFromIndexed.lookupFieldReference(nameName);
          getterReference =
              referencesFromIndexed.lookupGetterReference(nameName);
          setterReference =
              referencesFromIndexed.lookupSetterReference(nameName);
        }
        SourceFieldBuilder fieldBuilder = new SourceFieldBuilder(
            metadata,
            libraryBuilder.addInferableType(),
            name,
            constMask | staticMask | hasInitializerMask,
            /* isTopLevel = */ false,
            libraryBuilder,
            enumConstantInfo.charOffset,
            enumConstantInfo.charOffset,
            staticFieldNameScheme,
            fieldReference: fieldReference,
            fieldGetterReference: getterReference,
            fieldSetterReference: setterReference,
            initializerToken: enumConstantInfo.argumentsBeginToken,
            isEnumElement: true);
        members[name] = fieldBuilder..next = existing;
        elementBuilders.add(fieldBuilder);
      }
    }

    SourceEnumBuilder enumBuilder = new SourceEnumBuilder.internal(
        metadata,
        name,
        typeVariables,
        supertypeBuilder,
        interfaceBuilders,
        new Scope(
            kind: ScopeKind.declaration,
            local: members,
            setters: setters,
            parent: scope.parent,
            debugName: "enum $name",
            isModifiable: false),
        constructorScope..addLocalMembers(constructors),
        cls,
        elementBuilders,
        enumConstantInfos,
        intType,
        listType,
        objectType,
        stringType,
        selfType,
        libraryBuilder,
        constructorReferences,
        startCharOffsetComputed,
        charOffset,
        charEndOffset,
        referencesFromIndexed)
      ..synthesizedDefaultConstructorBuilder =
          synthesizedDefaultConstructorBuilder;

    void setParent(MemberBuilder? builder) {
      while (builder != null) {
        builder.parent = enumBuilder;
        builder = builder.next as MemberBuilder?;
      }
    }

    Map<String, TypeVariableBuilder>? typeVariablesByName;
    if (typeVariables != null) {
      typeVariablesByName = {};
      for (TypeVariableBuilder typeVariable in typeVariables) {
        typeVariablesByName[typeVariable.name] = typeVariable;
      }
    }

    void setParentAndCheckConflicts(String name, Builder member) {
      if (typeVariablesByName != null) {
        TypeVariableBuilder? tv = typeVariablesByName[name];
        if (tv != null) {
          enumBuilder.addProblem(
              templateConflictsWithTypeVariable.withArguments(name),
              member.charOffset,
              name.length,
              context: [
                messageConflictsWithTypeVariableCause.withLocation(
                    tv.fileUri!, tv.charOffset, name.length)
              ]);
        }
      }
      setParent(member as MemberBuilder);
    }

    members.forEach(setParentAndCheckConflicts);
    constructorScope
        .filteredIterator(includeDuplicates: false, includeAugmentations: true)
        .forEach(setParent);
    selfType.bind(libraryBuilder, enumBuilder);

    Iterator<MemberBuilder> constructorIterator = constructorScope
        .filteredIterator(includeDuplicates: false, includeAugmentations: true);
    while (constructorIterator.moveNext()) {
      MemberBuilder constructorBuilder = constructorIterator.current;
      if (!constructorBuilder.isFactory && !constructorBuilder.isConst) {
        libraryBuilder.addProblem(messageEnumNonConstConstructor,
            constructorBuilder.charOffset, noLength, fileUri);
      }
    }

    if (enumBuilder.name == "values") {
      libraryBuilder.addProblem(messageEnumWithNameValues,
          enumBuilder.charOffset, enumBuilder.name.length, fileUri);
    }

    return enumBuilder;
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
    assert(enumType is NamedTypeBuilder && enumType.name == "_Enum");
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
  BodyBuilderContext get bodyBuilderContext => new EnumBodyBuilderContext(this);

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
        constructorScope.lookupLocalMember(constructorName);

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
              libraryBuilder, bodyBuilderContext, scope, fileUri);
      bodyBuilder.constantContext = ConstantContext.inferred;

      if (enumConstantInfo.argumentsBeginToken != null) {
        arguments =
            bodyBuilder.parseArguments(enumConstantInfo.argumentsBeginToken!);
        // We pass `true` for [allowFurtherDelays] here because the members of
        // the enums are built before the inference, and the resolution of the
        // redirecting factories can't be completed at this moment and
        // therefore should be delayed to another invocation of
        // [BodyBuilder.performBacklogComputations].
        bodyBuilder.performBacklogComputations(
            delayedActionPerformers: _delayedActionPerformers,
            allowFurtherDelays: true);

        arguments.positional.insertAll(0, enumSyntheticArguments);
        arguments.argumentsOriginalOrder?.insertAll(0, enumSyntheticArguments);
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
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
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
            typeArgument: instantiateToBounds(
                rawType(libraryBuilder.nonNullable),
                classHierarchy.coreTypes.objectClass,
                isNonNullableByDefault: libraryBuilder.isNonNullableByDefault),
            isConst: true));

    for (SourceFieldBuilder elementBuilder in elementBuilders) {
      elementBuilder.type.registerInferredType(
          buildElement(elementBuilder, classHierarchy.coreTypes));
    }
    delayedActionPerformers.addAll(_delayedActionPerformers);
    _delayedActionPerformers.clear();

    SourceProcedureBuilder toStringBuilder =
        firstMemberNamed("_enumToString") as SourceProcedureBuilder;

    Name toStringName =
        new Name("_enumToString", classHierarchy.coreTypes.coreLibrary);
    Member? superToString = cls.superclass != null
        ? classHierarchy.getDispatchTarget(cls.superclass!, toStringName)
        : null;
    Procedure? toStringSuperTarget = superToString is Procedure &&
            superToString.enclosingClass != classHierarchy.coreTypes.objectClass
        ? superToString
        : null;

    if (toStringSuperTarget != null) {
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

    super.buildOutlineExpressions(
        classHierarchy, delayedActionPerformers, delayedDefaultValueCloners);
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
