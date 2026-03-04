// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/metadata/expressions.dart' as shared;
import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/reference_from_index.dart' show IndexedClass;
import 'package:kernel/src/bounds_checks.dart';
import 'package:kernel/transformations/flags.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/experimental_flags.dart';
import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/modifiers.dart' show Modifiers;
import '../base/scope.dart';
import '../base/uri_offset.dart';
import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/factory_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/method_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/property_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/constructor/declaration.dart';
import '../fragment/constructor/encoding.dart';
import '../fragment/field/declaration.dart';
import '../fragment/fragment.dart';
import '../fragment/getter/declaration.dart';
import '../fragment/method/declaration.dart';
import '../fragment/method/encoding.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/members_builder.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/member_covariance.dart';
import '../kernel/type_algorithms.dart';
import '../kernel/utils.dart';
import '../util/helpers.dart';
import 'builder_factory.dart';
import 'name_scheme.dart';
import 'name_space_builder.dart';
import 'source_class_builder.dart' show SourceClassBuilder;
import 'source_constructor_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_member_builder.dart';
import 'source_method_builder.dart';
import 'source_property_builder.dart';
import 'source_type_parameter_builder.dart';
import 'type_parameter_factory.dart';

class SourceEnumBuilder extends SourceClassBuilder {
  final int startOffset;
  final int endOffset;

  final ClassDeclaration _introductory;

  final List<EnumElementFragment> _enumElements;

  final TypeBuilder _underscoreEnumTypeBuilder;

  late final NamedTypeBuilder objectType;

  late final NamedTypeBuilder listType;

  late final NamedTypeBuilder selfType;

  SourceConstructorBuilder? _synthesizedDefaultConstructorBuilder;

  late final _EnumValuesFieldDeclaration _enumValuesFieldDeclaration;

  SourceEnumBuilder.internal({
    required String name,
    required List<SourceNominalParameterBuilder>? typeParameters,
    required TypeBuilder underscoreEnumTypeBuilder,
    required LookupScope typeParameterScope,
    required DeclarationNameSpaceBuilder nameSpaceBuilder,
    required List<EnumElementFragment> enumElements,
    required SourceLibraryBuilder libraryBuilder,
    required Uri fileUri,
    required this.startOffset,
    required int nameOffset,
    required this.endOffset,
    required IndexedClass? indexedClass,
    required ClassDeclaration classDeclaration,
  }) : _underscoreEnumTypeBuilder = underscoreEnumTypeBuilder,
       _introductory = classDeclaration,
       _enumElements = enumElements,
       super(
         modifiers: Modifiers.empty,
         name: name,
         typeParameters: typeParameters,
         typeParameterScope: typeParameterScope,
         nameSpaceBuilder: nameSpaceBuilder,
         libraryBuilder: libraryBuilder,
         fileUri: fileUri,
         nameOffset: nameOffset,
         indexedClass: indexedClass,
         introductory: classDeclaration,
       );

  factory SourceEnumBuilder({
    required String name,
    required List<SourceNominalParameterBuilder>? typeParameters,
    required TypeBuilder underscoreEnumTypeBuilder,
    required List<TypeBuilder>? interfaceBuilders,
    required List<EnumElementFragment> enumElements,
    required SourceLibraryBuilder libraryBuilder,
    required Uri fileUri,
    required int startOffset,
    required int nameOffset,
    required int endOffset,
    required IndexedClass? indexedClass,
    required LookupScope typeParameterScope,
    required DeclarationNameSpaceBuilder nameSpaceBuilder,
    required ClassDeclaration classDeclaration,
  }) {
    SourceEnumBuilder enumBuilder = new SourceEnumBuilder.internal(
      name: name,
      typeParameters: typeParameters,
      underscoreEnumTypeBuilder: underscoreEnumTypeBuilder,
      typeParameterScope: typeParameterScope,
      nameSpaceBuilder: nameSpaceBuilder,
      enumElements: enumElements,
      libraryBuilder: libraryBuilder,
      fileUri: fileUri,
      startOffset: startOffset,
      nameOffset: nameOffset,
      endOffset: endOffset,
      indexedClass: indexedClass,
      classDeclaration: classDeclaration,
    );
    return enumBuilder;
  }

  @override
  void buildScopes(LibraryBuilder coreLibrary) {
    _createTypeBuilders(coreLibrary);
    super.buildScopes(coreLibrary);
    _createSynthesizedMembers(coreLibrary);

    Iterator<ConstructorBuilder> constructorIterator =
        filteredConstructorsIterator(includeDuplicates: false);
    while (constructorIterator.moveNext()) {
      ConstructorBuilder constructorBuilder = constructorIterator.current;
      if (!constructorBuilder.isConst) {
        libraryBuilder.addProblem(
          diag.enumNonConstConstructor,
          constructorBuilder.fileOffset,
          noLength,
          fileUri,
        );
      }
    }
  }

  @override
  Map<String, SyntheticDeclaration>? createSyntheticDeclarations() {
    _enumValuesFieldDeclaration = new _EnumValuesFieldDeclaration(
      this,
      listType,
    );
    return {
      'values': new EnumValuesDeclaration(
        name: 'values',
        uriOffset: new UriOffset(fileUri, fileOffset),
        field: _enumValuesFieldDeclaration,
        getter: _enumValuesFieldDeclaration,
      ),
    };
  }

  void _createTypeBuilders(LibraryBuilder coreLibrary) {
    // TODO(ahe): These types shouldn't be looked up in scope, they come
    // directly from dart:core.
    objectType = new NamedTypeBuilderImpl(
      const PredefinedTypeName("Object"),
      const NullabilityBuilder.omitted(),
      instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected,
    );
    selfType = new NamedTypeBuilderImpl(
      new SyntheticTypeName(name, fileOffset),
      const NullabilityBuilder.omitted(),
      instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected,
      fileUri: fileUri,
      charOffset: fileOffset,
    );
    listType = new NamedTypeBuilderImpl(
      const PredefinedTypeName("List"),
      const NullabilityBuilder.omitted(),
      arguments: <TypeBuilder>[selfType],
      instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected,
    );
  }

  void _createSynthesizedMembers(LibraryBuilder coreLibrary) {
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

    Reference? toStringReference;
    if (indexedClass != null) {
      toStringReference = indexedClass!.lookupGetterReference(
        new Name("_enumToString", coreLibrary.library),
      );
    }

    for (String restrictedInstanceMemberName in const [
      "index",
      "hashCode",
      "==",
    ]) {
      NamedBuilder? customIndexDeclaration = nameSpace
          .lookup(restrictedInstanceMemberName)
          ?.getable;
      NamedBuilder? invalidDeclaration;
      if (customIndexDeclaration is PropertyBuilder &&
          !customIndexDeclaration.hasAbstractGetter &&
          !customIndexDeclaration.isEnumElement) {
        invalidDeclaration = customIndexDeclaration;
      } else if (customIndexDeclaration is MethodBuilder &&
          !customIndexDeclaration.isAbstract) {
        invalidDeclaration = customIndexDeclaration;
      }
      if (invalidDeclaration != null) {
        // Retrieve the earliest declaration for error reporting.
        while (customIndexDeclaration?.next != null) {
          // Coverage-ignore-block(suite): Not run.
          customIndexDeclaration = customIndexDeclaration?.next;
        }
        libraryBuilder.addProblem(
          diag.enumContainsRestrictedInstanceDeclaration.withArguments(
            memberName: restrictedInstanceMemberName,
          ),
          customIndexDeclaration!.fileOffset,
          customIndexDeclaration.fullNameForErrors.length,
          fileUri,
        );
      }
    }

    // The default constructor is added if no generative or unnamed factory
    // constructors are declared.
    bool needsSynthesizedDefaultConstructor = true;
    Iterator<MemberBuilder> iterator = unfilteredConstructorsIterator;
    while (iterator.moveNext()) {
      MemberBuilder constructorBuilder = iterator.current;
      if (constructorBuilder is! FactoryBuilder ||
          constructorBuilder.name == "") {
        needsSynthesizedDefaultConstructor = false;
        break;
      }
    }
    if (needsSynthesizedDefaultConstructor) {
      bool isClosureContextLoweringEnabled = libraryBuilder
          .loader
          .target
          .backendTarget
          .flags
          .isClosureContextLoweringEnabled;
      ConstructorEncodingStrategy encodingStrategy =
          new ConstructorEncodingStrategy(
            this,
            isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
          );

      FormalParameterBuilder nameFormalParameterBuilder =
          new FormalParameterBuilder(
            kind: FormalParameterKind.requiredPositional,
            modifiers: Modifiers.empty,
            type: libraryBuilder.loader.target.stringType,
            name: "#name",
            nameOffset: null,
            fileOffset: fileOffset,
            fileUri: fileUri,
            hasImmediatelyDeclaredInitializer: false,
            isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
          );

      FormalParameterBuilder indexFormalParameterBuilder =
          new FormalParameterBuilder(
            kind: FormalParameterKind.requiredPositional,
            modifiers: Modifiers.empty,
            type: libraryBuilder.loader.target.intType,
            name: "#index",
            nameOffset: null,
            fileOffset: fileOffset,
            fileUri: fileUri,
            hasImmediatelyDeclaredInitializer: false,
            isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
          );

      ConstructorDeclaration constructorDeclaration =
          new DefaultEnumConstructorDeclaration(
            returnType: libraryBuilder.loader.inferableTypes.addInferableType(
              InferenceDefaultType.Dynamic,
            ),
            formals: [indexFormalParameterBuilder, nameFormalParameterBuilder],
            fileUri: fileUri,
            fileOffset: fileOffset,
            extensionScope: _introductory.extensionScope,
            lookupScope: _introductory.compilationUnitScope,
          );

      NameScheme nameScheme = new NameScheme(
        isInstanceMember: false,
        containerName: new ClassName(name),
        containerType: ContainerType.Class,
        libraryName: libraryName,
      );

      ConstructorReferences constructorReferences = new ConstructorReferences(
        name: '',
        nameScheme: nameScheme,
        indexedContainer: indexedClass,
        loader: libraryBuilder.loader,
        declarationBuilder: this,
      );

      SourceConstructorBuilder constructorBuilder =
          _synthesizedDefaultConstructorBuilder = new SourceConstructorBuilder(
            name: "",
            libraryBuilder: libraryBuilder,
            declarationBuilder: this,
            fileUri: fileUri,
            fileOffset: fileOffset,
            constructorReferences: constructorReferences,
            nameScheme: nameScheme,
            introductory: constructorDeclaration,
            isConst: true,
          );
      constructorDeclaration.createEncoding(
        problemReporting: libraryBuilder,
        loader: libraryBuilder.loader,
        declarationBuilder: this,
        constructorBuilder: constructorBuilder,
        typeParameterFactory: libraryBuilder.typeParameterFactory,
        encodingStrategy: encodingStrategy,
      );

      addConstructorInternal(constructorBuilder, addToNameSpace: true);
      nameSpaceBuilder.checkTypeParameterConflict(
        libraryBuilder,
        _synthesizedDefaultConstructorBuilder!.name,
        _synthesizedDefaultConstructorBuilder!,
        _synthesizedDefaultConstructorBuilder!.fileUri,
      );
    }

    SourceMethodBuilder toStringBuilder = new SourceMethodBuilder(
      name: "_enumToString",
      fileUri: fileUri,
      fileOffset: fileOffset,
      libraryBuilder: libraryBuilder,
      declarationBuilder: this,
      nameScheme: new NameScheme(
        isInstanceMember: true,
        containerName: new ClassName(name),
        containerType: ContainerType.Class,
        libraryName: new LibraryName(coreLibrary.library.reference),
      ),
      introductory: new _EnumToStringMethodDeclaration(
        this,
        libraryBuilder.loader.target.stringType,
        _underscoreEnumTypeBuilder,
        fileUri: fileUri,
        fileOffset: fileOffset,
      ),
      augmentations: const [],
      isStatic: false,
      modifiers: Modifiers.empty,
      reference: toStringReference,
      tearOffReference: null,
    );
    addMemberInternal(toStringBuilder, addToNameSpace: true);
    nameSpaceBuilder.checkTypeParameterConflict(
      libraryBuilder,
      toStringBuilder.name,
      toStringBuilder,
      toStringBuilder.fileUri,
    );

    selfType.bind(libraryBuilder, this);
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
        enumElement.declaration.elementIndex = elementIndex++;
      } else {
        enumElement.declaration.elementIndex = -1;
      }
    }

    bindCoreType(coreLibrary, objectType);
    bindCoreType(coreLibrary, listType);

    Class cls = super.build(coreLibrary);
    cls.isEnum = true;

    // The super initializer for the synthesized default constructor is
    // inserted here if the enum's supertype is _Enum to preserve the legacy
    // behavior or having the old-style enum constants built in the outlines.
    // Other constructors are handled in [Resolver._finishConstructor] as
    // they are processed via the pipeline for constructor parsing and
    // building.
    if (identical(this.supertypeBuilder, _underscoreEnumTypeBuilder)) {
      if (_synthesizedDefaultConstructorBuilder != null) {
        Constructor constructor =
            _synthesizedDefaultConstructorBuilder!.invokeTarget as Constructor;
        ClassBuilder objectClass = objectType.declaration as ClassBuilder;
        ClassBuilder enumClass =
            _underscoreEnumTypeBuilder.declaration as ClassBuilder;
        MemberLookupResult? result = enumClass.findConstructorOrFactory(
          "",
          libraryBuilder,
        );
        MemberBuilder? superConstructor = result?.getable;
        if (result == null ||
            result.isInvalidLookup ||
            superConstructor == null ||
            superConstructor is! ConstructorBuilder) {
          // Coverage-ignore-block(suite): Not run.
          // TODO(ahe): Ideally, we would also want to check that [Object]'s
          // unnamed constructor requires no arguments. But that information
          // isn't always available at this point, and it's not really a
          // situation that can happen unless you start modifying the SDK
          // sources. (We should add a correct message. We no longer depend on
          // Object here.)
          libraryBuilder.addProblem(
            diag.noUnnamedConstructorInObject,
            objectClass.fileOffset,
            objectClass.name.length,
            objectClass.fileUri,
          );
        } else {
          constructor.initializers.add(
            new SuperInitializer.byReference(
              superConstructor.invokeTargetReference!,
              new Arguments.forwarded(
                constructor.function,
                libraryBuilder.library,
              ),
            )..parent = constructor,
          );
        }
        _synthesizedDefaultConstructorBuilder = null;
      }
    }

    return cls;
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    return new EnumBodyBuilderContext(this);
  }

  @override
  void buildOutlineExpressions(
    ClassHierarchy classHierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    for (EnumElementFragment enumElement in _enumElements) {
      enumElement.declaration.inferType(classHierarchy);
    }
    _enumValuesFieldDeclaration.inferType(classHierarchy);

    super.buildOutlineExpressions(classHierarchy, delayedDefaultValueCloners);
  }
}

class _EnumToStringMethodDeclaration implements MethodDeclaration {
  static const String _enumToStringName = "_enumToString";

  final SourceEnumBuilder _enumBuilder;
  final TypeBuilder _stringTypeBuilder;
  final TypeBuilder _underscoreEnumTypeBuilder;

  final Uri _fileUri;
  final int _fileOffset;
  late final Procedure _procedure;

  _EnumToStringMethodDeclaration(
    this._enumBuilder,
    this._stringTypeBuilder,
    this._underscoreEnumTypeBuilder, {
    required Uri fileUri,
    required int fileOffset,
  }) : _fileUri = fileUri,
       _fileOffset = fileOffset;

  @override
  UriOffsetLength get uriOffset => new UriOffset(_fileUri, _fileOffset);

  @override
  void buildOutlineExpressions({
    required ClassHierarchy classHierarchy,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required SourceMethodBuilder methodBuilder,
    required Annotatable annotatable,
    required Uri annotatableFileUri,
  }) {
    Name toStringName = new Name(
      _enumToStringName,
      classHierarchy.coreTypes.coreLibrary,
    );
    Member? superToString = _enumBuilder.cls.superclass != null
        ? classHierarchy.getDispatchTarget(
            _enumBuilder.cls.superclass!,
            toStringName,
          )
        : null;
    Procedure? toStringSuperTarget =
        superToString is Procedure &&
            // Coverage-ignore(suite): Not run.
            superToString.enclosingClass != classHierarchy.coreTypes.objectClass
        ? superToString
        : null;

    if (toStringSuperTarget != null) {
      // Coverage-ignore-block(suite): Not run.
      _procedure.transformerFlags |= TransformerFlag.superCalls;
      _procedure.function.registerFunctionBody(
        new ReturnStatement(
          new SuperMethodInvocation(
            new ThisExpression(),
            toStringName,
            new Arguments([]),
            toStringSuperTarget,
          ),
        ),
      );
    } else {
      ClassBuilder enumClass =
          _underscoreEnumTypeBuilder.declaration as ClassBuilder;
      MemberBuilder? nameFieldBuilder = enumClass
          .lookupLocalMember("_name")
          ?.getable;
      assert(nameFieldBuilder != null);
      Field nameField = nameFieldBuilder!.readTarget as Field;

      _procedure.function.registerFunctionBody(
        new ReturnStatement(
          new StringConcatenation([
            new StringLiteral("${_enumBuilder.cls.demangledName}."),
            new InstanceGet.byReference(
              InstanceAccessKind.Instance,
              new ThisExpression(),
              nameField.name,
              interfaceTargetReference: nameField.getterReference,
              resultType: nameField.getterType,
            ),
          ]),
        ),
      );
    }
  }

  @override
  void buildOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    ProblemReporting problemReporting,
    NameScheme nameScheme,
    BuildNodesCallback f, {
    required Reference reference,
    required Reference? tearOffReference,
    required List<TypeParameter>? classTypeParameters,
  }) {
    FunctionNode function =
        new FunctionNode(
            new EmptyStatement()..fileOffset = _fileOffset,
            returnType: _stringTypeBuilder.build(
              libraryBuilder,
              TypeUse.returnType,
            ),
          )
          ..fileOffset = _fileOffset
          ..fileEndOffset = _fileOffset;
    _procedure =
        new Procedure(
            nameScheme.getDeclaredName(_enumToStringName).name,
            ProcedureKind.Method,
            function,
            fileUri: fileUri,
            reference: reference,
          )
          ..fileOffset = _fileOffset
          ..fileEndOffset = _fileOffset
          ..transformerFlags |= TransformerFlag.superCalls;
    f(kind: BuiltMemberKind.Method, member: _procedure);
  }

  @override
  void checkTypes(
    ProblemReporting problemReporting,
    TypeEnvironment typeEnvironment,
  ) {}

  @override
  void checkVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {}

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    return 0;
  }

  @override
  void createEncoding(
    ProblemReporting problemReporting,
    SourceMethodBuilder builder,
    MethodEncodingStrategy encodingStrategy,
    TypeParameterFactory typeParameterFactory,
  ) {
    throw new UnsupportedError("$runtimeType.createEncoding");
  }

  @override
  void ensureTypes(
    ClassMembersBuilder membersBuilder,
    SourceClassBuilder enclosingClassBuilder,
    Set<ClassMember>? overrideDependencies,
  ) {}

  @override
  Uri get fileUri => _fileUri;

  @override
  Procedure get invokeTarget => _procedure;

  @override
  bool get isOperator => false;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => null;

  @override
  Procedure? get readTarget => null;
}

class _EnumValuesFieldDeclaration
    implements FieldDeclaration, GetterDeclaration {
  static const String name = "values";

  final SourceEnumBuilder _sourceEnumBuilder;

  SourcePropertyBuilder? _builder;

  DartType _type = const DynamicType();

  Field? _field;

  final TypeBuilder _typeBuilder;

  _EnumValuesFieldDeclaration(this._sourceEnumBuilder, this._typeBuilder);

  @override
  UriOffsetLength get uriOffset =>
      new UriOffset(_sourceEnumBuilder.fileUri, _sourceEnumBuilder.fileOffset);

  SourcePropertyBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourcePropertyBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  void createFieldEncoding(SourcePropertyBuilder builder) {
    this.builder = builder;
  }

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError('${runtimeType}.buildImplicitDefaultValue');
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError('${runtimeType}.buildImplicitInitializer');
  }

  @override
  List<Initializer> buildInitializer(
    int fileOffset,
    Expression value, {
    required bool isSynthetic,
  }) {
    throw new UnsupportedError('${runtimeType}.buildInitializer');
  }

  @override
  void buildFieldOutlineExpressions({
    required ClassHierarchy classHierarchy,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<Annotatable> annotatables,
    required Uri annotatablesFileUri,
    required bool isClassInstanceMember,
  }) {
    List<Expression> values = <Expression>[];
    for (EnumElementFragment enumElement in _sourceEnumBuilder._enumElements) {
      enumElement.declaration.inferType(classHierarchy);
      if (!enumElement.builder.isDuplicate) {
        values.add(new StaticGet(enumElement.declaration.readTarget));
      }
    }

    _field!.initializer = new ListLiteral(
      values,
      typeArgument: instantiateToBounds(
        _sourceEnumBuilder.rawType(Nullability.nonNullable),
        classHierarchy.coreTypes.objectClass,
      ),
      isConst: true,
    )..parent = _field;
  }

  @override
  void buildFieldOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    BuildNodesCallback f,
    PropertyReferences references, {
    required List<TypeParameter>? classTypeParameters,
  }) {
    fieldType = _typeBuilder.build(libraryBuilder, TypeUse.fieldType);
    _field =
        new Field.immutable(
            dummyName,
            type: _type,
            isFinal: false,
            isConst: true,
            isStatic: true,
            fileUri: uriOffset.fileUri,
            fieldReference: references.fieldReference,
            getterReference: references.getterReference,
            isEnumElement: false,
          )
          ..fileOffset = uriOffset.fileOffset
          ..fileEndOffset = uriOffset.fileOffset;
    nameScheme
        .getFieldMemberName(FieldNameType.Field, name, isSynthesized: false)
        .attachMember(_field!);
    f(member: _field!, kind: BuiltMemberKind.Field);
  }

  @override
  void checkFieldTypes(
    ProblemReporting problemReporting,
    TypeEnvironment typeEnvironment,
    SourcePropertyBuilder? setterBuilder,
  ) {}

  @override
  // Coverage-ignore(suite): Not run.
  void checkFieldVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {}

  @override
  int computeFieldDefaultTypes(ComputeDefaultTypeContext context) {
    return 0;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void ensureTypes(
    ClassMembersBuilder membersBuilder,
    Set<ClassMember>? getterOverrideDependencies,
    Set<ClassMember>? setterOverrideDependencies,
  ) {
    inferType(membersBuilder.hierarchyBuilder);
  }

  @override
  bool get hasInitializer => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasSetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  shared.Expression? get initializerExpression => null;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExtensionTypeDeclaredInstanceField => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => false;

  @override
  bool get isLate => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => true;

  @override
  List<ClassMember> get localMembers => [
    new _EnumValuesClassMember(builder, uriOffset),
  ];

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => null;

  @override
  Member get readTarget => _field!;

  @override
  // Coverage-ignore(suite): Not run.
  DartType get fieldType => _type;

  @override
  void set fieldType(DartType value) {
    _type = value;
    _field
            // Coverage-ignore(suite): Not run.
            ?.type =
        value;
  }

  @override
  DartType inferType(ClassHierarchyBase hierarchy) {
    return _type;
  }

  @override
  FieldQuality get fieldQuality => FieldQuality.Concrete;

  @override
  GetterQuality get getterQuality => GetterQuality.Implicit;

  @override
  void buildGetterOutlineExpressions({
    required ClassHierarchy classHierarchy,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required SourcePropertyBuilder propertyBuilder,
    required Annotatable annotatable,
    required Uri annotatableFileUri,
  }) {}

  @override
  void buildGetterOutlineNode({
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required BuildNodesCallback f,
    required PropertyReferences? references,
    required List<TypeParameter>? classTypeParameters,
  }) {}

  @override
  void checkGetterTypes(
    ProblemReporting problemReporting,
    LibraryFeatures libraryFeatures,
    TypeEnvironment typeEnvironment,
    SourcePropertyBuilder? setterBuilder,
  ) {}

  @override
  // Coverage-ignore(suite): Not run.
  void checkGetterVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {}

  @override
  int computeGetterDefaultTypes(ComputeDefaultTypeContext context) {
    return 0;
  }

  @override
  void createGetterEncoding(
    ProblemReporting problemReporting,
    SourcePropertyBuilder builder,
    PropertyEncodingStrategy encodingStrategy,
    TypeParameterFactory typeParameterFactory,
  ) {}

  @override
  // Coverage-ignore(suite): Not run.
  void ensureGetterTypes({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required ClassMembersBuilder membersBuilder,
    required Set<ClassMember>? getterOverrideDependencies,
  }) {}

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => _sourceEnumBuilder.fileUri;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> getExportedGetterReferences(
    PropertyReferences references,
  ) {
    return [references.getterReference];
  }

  @override
  Initializer takePrimaryConstructorFieldInitializer() {
    throw new UnsupportedError(
      "${runtimeType}.takePrimaryConstructorFieldInitializer",
    );
  }
}

class _EnumValuesClassMember implements ClassMember {
  final SourcePropertyBuilder _builder;

  @override
  final UriOffsetLength uriOffset;

  Covariance? _covariance;

  _EnumValuesClassMember(this._builder, this.uriOffset);

  @override
  bool get forSetter => false;

  @override
  DeclarationBuilder get declarationBuilder => _builder.declarationBuilder!;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get declarations =>
      throw new UnsupportedError('$runtimeType.declarations');

  @override
  // Coverage-ignore(suite): Not run.
  String get fullName {
    String className = declarationBuilder.fullNameForErrors;
    return "${className}.${fullNameForErrors}";
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors => _builder.fullNameForErrors;

  @override
  // Coverage-ignore(suite): Not run.
  Covariance getCovariance(ClassMembersBuilder membersBuilder) {
    return _covariance ??= forSetter
        ? new Covariance.fromMember(
            getMember(membersBuilder),
            forSetter: forSetter,
          )
        : const Covariance.empty();
  }

  @override
  Member getMember(ClassMembersBuilder membersBuilder) {
    inferType(membersBuilder);
    return forSetter
        ?
          // Coverage-ignore(suite): Not run.
          _builder.writeTarget!
        : _builder.readTarget!;
  }

  @override
  // Coverage-ignore(suite): Not run.
  MemberResult getMemberResult(ClassMembersBuilder membersBuilder) {
    return new StaticMemberResult(
      getMember(membersBuilder),
      memberKind,
      isDeclaredAsField: true,
      fullName: '${declarationBuilder.name}.${_builder.memberName.text}',
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Member? getTearOff(ClassMembersBuilder membersBuilder) => null;

  @override
  bool get hasDeclarations => false;

  @override
  void inferType(ClassMembersBuilder membersBuilder) {
    _builder.inferFieldType(membersBuilder.hierarchyBuilder);
  }

  @override
  ClassMember get interfaceMember => this;

  @override
  bool get isAbstract => false;

  @override
  bool get isDuplicate => _builder.isDuplicate;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExtensionTypeMember => _builder.isExtensionTypeMember;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNoSuchMethodForwarder => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool isObjectMember(ClassBuilder objectClass) {
    return declarationBuilder == objectClass;
  }

  @override
  bool get isProperty => true;

  @override
  bool isSameDeclaration(ClassMember other) {
    return other is _EnumValuesClassMember &&
        // Coverage-ignore(suite): Not run.
        _builder == other._builder;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSourceDeclaration => true;

  @override
  bool get isStatic => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => true;

  @override
  // Coverage-ignore(suite): Not run.
  ClassMemberKind get memberKind => ClassMemberKind.Getter;

  @override
  Name get name => _builder.memberName;

  @override
  // Coverage-ignore(suite): Not run.
  void registerOverrideDependency(
    ClassMembersBuilder membersBuilder,
    Set<ClassMember> overriddenMembers,
  ) {
    _builder.registerGetterOverrideDependency(
      membersBuilder,
      overriddenMembers,
    );
  }

  @override
  String toString() => '$runtimeType($fullName)';
}
