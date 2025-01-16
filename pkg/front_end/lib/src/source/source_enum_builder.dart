// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:front_end/src/source/synthetic_method_builder.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/reference_from_index.dart' show IndexedClass;
import 'package:kernel/src/bounds_checks.dart';
import 'package:kernel/transformations/flags.dart';

import '../base/modifiers.dart' show Modifiers;
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/method_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/type_builder.dart';
import '../codes/cfe_codes.dart'
    show
        messageEnumContainsValuesDeclaration,
        messageEnumNonConstConstructor,
        messageEnumWithNameValues,
        messageNoUnnamedConstructorInObject,
        noLength,
        templateEnumContainsRestrictedInstanceDeclaration;
import '../fragment/fragment.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/kernel_helper.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart' show SourceClassBuilder;
import 'source_constructor_builder.dart';
import 'source_field_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'type_parameter_scope_builder.dart';

class SourceEnumBuilder extends SourceClassBuilder {
  final int startOffset;
  final int endOffset;

  final List<EnumElementFragment> _enumElements;

  final TypeBuilder _underscoreEnumTypeBuilder;

  late final NamedTypeBuilder intType;

  late final NamedTypeBuilder stringType;

  late final NamedTypeBuilder objectType;

  late final NamedTypeBuilder listType;

  late final NamedTypeBuilder selfType;

  DeclaredSourceConstructorBuilder? synthesizedDefaultConstructorBuilder;

  SourceEnumBuilder.internal(
      {required List<MetadataBuilder>? metadata,
      required String name,
      required List<NominalParameterBuilder>? typeParameters,
      required TypeBuilder underscoreEnumTypeBuilder,
      required TypeBuilder supertypeBuilder,
      required List<TypeBuilder>? interfaceBuilders,
      required LookupScope typeParameterScope,
      required DeclarationNameSpaceBuilder nameSpaceBuilder,
      required List<EnumElementFragment> enumElements,
      required SourceLibraryBuilder libraryBuilder,
      required List<ConstructorReferenceBuilder> constructorReferences,
      required Uri fileUri,
      required this.startOffset,
      required int nameOffset,
      required this.endOffset,
      required IndexedClass? indexedClass})
      : _underscoreEnumTypeBuilder = underscoreEnumTypeBuilder,
        _enumElements = enumElements,
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
      required List<EnumElementFragment> enumElements,
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
        enumElements: enumElements,
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
          !customIndexDeclaration.isAbstract &&
          !customIndexDeclaration.isEnumElement) {
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

    MethodBuilder toStringBuilder = new SyntheticMethodBuilder(
        name: "_enumToString",
        fileUri: fileUri,
        fileOffset: fileOffset,
        libraryBuilder: libraryBuilder,
        declarationBuilder: this,
        nameScheme: new NameScheme(
            isInstanceMember: true,
            containerName: new ClassName(name),
            containerType: ContainerType.Class,
            libraryName: new LibraryName(coreLibrary.library.reference)),
        isAbstract: false,
        reference: toStringReference,
        creator: new _EnumToStringCreator(
            this, stringType, _underscoreEnumTypeBuilder));
    nameSpace.addLocalMember(toStringBuilder.name, toStringBuilder,
        setter: false);
    nameSpaceBuilder.checkTypeParameterConflict(libraryBuilder,
        toStringBuilder.name, toStringBuilder, toStringBuilder.fileUri!);

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
    int elementIndex = 0;
    for (EnumElementFragment enumElement in _enumElements) {
      if (!enumElement.builder.isDuplicate) {
        enumElement.elementIndex = elementIndex++;
      } else {
        enumElement.elementIndex = -1;
      }
    }

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

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    List<Expression> values = <Expression>[];
    for (EnumElementFragment enumElement in _enumElements) {
      enumElement.inferType(classHierarchy);
      if (!enumElement.builder.isDuplicate) {
        values.add(new StaticGet(enumElement.readTarget));
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

    super.buildOutlineExpressions(classHierarchy, delayedDefaultValueCloners);
  }
}

class _EnumToStringCreator implements SyntheticMethodCreator {
  final SourceEnumBuilder _enumBuilder;
  final TypeBuilder _stringTypeBuilder;
  final TypeBuilder _underscoreEnumTypeBuilder;

  _EnumToStringCreator(this._enumBuilder, this._stringTypeBuilder,
      this._underscoreEnumTypeBuilder);

  @override
  Procedure buildOutlineNode(
      {required SourceLibraryBuilder libraryBuilder,
      required Name name,
      required Uri fileUri,
      required int fileOffset,
      required Reference reference}) {
    FunctionNode function = new FunctionNode(
        new EmptyStatement()..fileOffset = fileOffset,
        returnType:
            _stringTypeBuilder.build(libraryBuilder, TypeUse.returnType))
      ..fileOffset = fileOffset
      ..fileEndOffset = fileOffset;
    Procedure procedure = new Procedure(name, ProcedureKind.Method, function,
        fileUri: fileUri, reference: reference)
      ..fileOffset = fileOffset
      ..fileEndOffset = fileOffset;
    procedure.transformerFlags |= TransformerFlag.superCalls;
    return procedure;
  }

  @override
  void buildOutlineExpressions(
      {required Procedure procedure, required ClassHierarchy classHierarchy}) {
    Name toStringName =
        new Name("_enumToString", classHierarchy.coreTypes.coreLibrary);
    Member? superToString = _enumBuilder.cls.superclass != null
        ? classHierarchy.getDispatchTarget(
            _enumBuilder.cls.superclass!, toStringName)
        : null;
    Procedure? toStringSuperTarget = superToString is Procedure &&
            // Coverage-ignore(suite): Not run.
            superToString.enclosingClass != classHierarchy.coreTypes.objectClass
        ? superToString
        : null;

    if (toStringSuperTarget != null) {
      // Coverage-ignore-block(suite): Not run.
      procedure.transformerFlags |= TransformerFlag.superCalls;
      procedure.function.body = new ReturnStatement(new SuperMethodInvocation(
          toStringName, new Arguments([]), toStringSuperTarget))
        ..parent = procedure.function;
    } else {
      ClassBuilder enumClass =
          _underscoreEnumTypeBuilder.declaration as ClassBuilder;
      MemberBuilder? nameFieldBuilder =
          enumClass.lookupLocalMember("_name") as MemberBuilder?;
      assert(nameFieldBuilder != null);
      Field nameField = nameFieldBuilder!.readTarget as Field;

      procedure.function.body = new ReturnStatement(new StringConcatenation([
        new StringLiteral("${_enumBuilder.cls.demangledName}."),
        new InstanceGet.byReference(
            InstanceAccessKind.Instance, new ThisExpression(), nameField.name,
            interfaceTargetReference: nameField.getterReference,
            resultType: nameField.getterType),
      ]))
        ..parent = procedure.function;
    }
  }
}
