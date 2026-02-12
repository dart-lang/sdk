// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClassHierarchyMembers;
import 'package:kernel/core_types.dart';
import 'package:kernel/names.dart' show equalsName;
import 'package:kernel/reference_from_index.dart'
    show IndexedClass, IndexedLibrary;
import 'package:kernel/src/bounds_checks.dart';
import 'package:kernel/src/types.dart' show Types;
import 'package:kernel/type_algebra.dart'
    show
        FreshTypeParameters,
        Substitution,
        getFreshTypeParameters,
        substitute,
        updateBoundNullabilities;
import 'package:kernel/type_environment.dart';

import '../base/extension_scope.dart';
import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../base/problems.dart' show unexpected, unhandled, unimplemented;
import '../base/scope.dart';
import '../base/uri_offset.dart';
import '../builder/augmentation_iterator.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/method_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/never_type_declaration_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/property_builder.dart';
import '../builder/synthesized_type_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/fragment.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/hierarchy/hierarchy_builder.dart';
import '../kernel/hierarchy/hierarchy_node.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/utils.dart' show compareProcedures;
import 'builder_factory.dart';
import 'check_helper.dart';
import 'name_scheme.dart';
import 'name_space_builder.dart';
import 'nominal_parameter_name_space.dart';
import 'source_builder_mixins.dart';
import 'source_constructor_builder.dart';
import 'source_declaration_builder.dart';
import 'source_factory_builder.dart';
import 'source_library_builder.dart';
import 'source_loader.dart';
import 'source_member_builder.dart';
import 'source_type_parameter_builder.dart';
import 'type_parameter_factory.dart';

Class initializeClass(
  List<SourceNominalParameterBuilder>? typeParameters,
  String name,
  Uri fileUri,
  int startOffset,
  int nameOffset,
  int endOffset,
  IndexedClass? indexedClass, {
  required bool isAugmentation,
}) {
  Class cls = new Class(
    name: name,
    typeParameters: SourceNominalParameterBuilder.typeParametersFromBuilders(
      typeParameters,
    ),
    // If the class is an augmentation class it shouldn't use the reference
    // from index even when available.
    // TODO(johnniwinther): Avoid creating [Class] so early in the builder
    // that we end up creating unneeded nodes.
    reference: isAugmentation ? null : indexedClass?.reference,
    fileUri: fileUri,
  );
  if (cls.startFileOffset == TreeNode.noOffset) {
    cls.startFileOffset = startOffset;
  }
  if (cls.fileOffset == TreeNode.noOffset) {
    cls.fileOffset = nameOffset;
  }
  if (cls.fileEndOffset == TreeNode.noOffset) {
    cls.fileEndOffset = endOffset;
  }

  return cls;
}

class SourceClassBuilder extends ClassBuilderImpl
    with SourceDeclarationBuilderBaseMixin
    implements Comparable<SourceClassBuilder>, SourceDeclarationBuilder {
  @override
  final SourceLibraryBuilder libraryBuilder;

  final int nameOffset;

  @override
  final String name;

  @override
  final Uri fileUri;

  final Modifiers _modifiers;

  @override
  final Class cls;

  final DeclarationNameSpaceBuilder nameSpaceBuilder;

  late final SourceDeclarationNameSpace _nameSpace;
  late final List<SourceMemberBuilder> _constructorBuilders;
  late final List<SourceMemberBuilder> _memberBuilders;

  @override
  List<SourceNominalParameterBuilder>? typeParameters;

  /// The scope in which the [typeParameters] are declared.
  final LookupScope typeParameterScope;

  TypeBuilder? _supertypeBuilder;

  List<TypeBuilder>? _interfaceBuilders;

  TypeBuilder? _mixedInTypeBuilder;

  final IndexedClass? indexedClass;

  final ClassDeclaration _introductory;
  List<ClassDeclaration> _augmentations;

  SourceClassBuilder({
    required Modifiers modifiers,
    required this.name,
    required this.typeParameters,
    required this.typeParameterScope,
    required this.nameSpaceBuilder,
    required this.libraryBuilder,
    required this.fileUri,
    required this.nameOffset,
    this.indexedClass,
    TypeBuilder? mixedInTypeBuilder,
    required ClassDeclaration introductory,
    List<ClassDeclaration> augmentations = const [],
  }) : _modifiers = modifiers,
       _introductory = introductory,
       _augmentations = augmentations,
       _mixedInTypeBuilder = mixedInTypeBuilder,
       cls = initializeClass(
         typeParameters,
         name,
         fileUri,
         introductory.startOffset,
         introductory.nameOffset,
         introductory.endOffset,
         indexedClass,
         isAugmentation: modifiers.isAugment,
       ) {
    cls.hasConstConstructor = declaresConstConstructor;
  }

  @override
  Iterator<SourceMemberBuilder> get unfilteredMembersIterator =>
      _memberBuilders.iterator;

  @override
  Iterator<T> filteredMembersIterator<T extends MemberBuilder>({
    required bool includeDuplicates,
  }) => new FilteredIterator<T>(
    _memberBuilders.iterator,
    includeDuplicates: includeDuplicates,
  );

  @override
  Iterator<SourceMemberBuilder> get unfilteredConstructorsIterator =>
      _constructorBuilders.iterator;

  @override
  Iterator<T> filteredConstructorsIterator<T extends MemberBuilder>({
    required bool includeDuplicates,
  }) => new FilteredIterator<T>(
    _constructorBuilders.iterator,
    includeDuplicates: includeDuplicates,
  );

  /// If the class has a primary constructor, returns the parameters
  /// available in the initializer scope. Otherwise return `null`.
  List<FormalParameterBuilder>?
  get primaryConstructorInitializerScopeParameters {
    for (SourceMemberBuilder constructorBuilder in _constructorBuilders) {
      if (constructorBuilder is SourceConstructorBuilder &&
          constructorBuilder.isPrimaryConstructor) {
        return constructorBuilder.primaryConstructorInitializerScopeParameters;
      }
    }
    return null;
  }

  void addMemberInternal(
    SourceMemberBuilder memberBuilder, {
    required bool addToNameSpace,
  }) {
    if (addToNameSpace) {
      _nameSpace.addLocalMember(memberBuilder.name, memberBuilder);
    }
    _memberBuilders.add(memberBuilder);
  }

  void addConstructorInternal(
    SourceMemberBuilder constructorBuilder, {
    required bool addToNameSpace,
  }) {
    if (addToNameSpace) {
      _nameSpace.addConstructor(constructorBuilder.name, constructorBuilder);
    }
    _constructorBuilders.add(constructorBuilder);
  }

  @override
  int resolveConstructors(SourceLibraryBuilder libraryBuilder) {
    int count = _introductory.resolveConstructorReferences(libraryBuilder);
    for (int i = 0; i < _augmentations.length; i++) {
      ClassDeclaration augmentation = _augmentations[i];
      count += augmentation.resolveConstructorReferences(libraryBuilder);
    }
    if (count > 0) {
      Iterator<SourceFactoryBuilder> iterator = filteredConstructorsIterator(
        includeDuplicates: true,
      );
      while (iterator.moveNext()) {
        SourceFactoryBuilder factoryBuilder = iterator.current;
        assert(
          factoryBuilder.declarationBuilder == this,
          "Unexpected builder $factoryBuilder in $this.",
        );
        factoryBuilder.resolveRedirectingFactory();
      }
    }
    return count;
  }

  @override
  int get fileOffset => nameOffset;

  @override
  bool get isAbstract => _modifiers.isAbstract;

  @override
  bool get isNamedMixinApplication {
    return isMixinApplication && _modifiers.isNamedMixinApplication;
  }

  @override
  bool get declaresConstConstructor => _modifiers.declaresConstConstructor;

  @override
  bool get isSealed => _modifiers.isSealed;

  @override
  bool get isBase => _modifiers.isBase;

  @override
  bool get isInterface => _modifiers.isInterface;

  @override
  bool get isFinal => _modifiers.isFinal;

  /// Set to `true` if this class is declared using the `augment` modifier.
  bool get isAugmentation => _modifiers.isAugment;

  @override
  bool get isMixinClass => _modifiers.isMixin;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isStatic => _modifiers.isStatic;

  @override
  bool get isMixinDeclaration => _introductory.isMixinDeclaration;

  @override
  DeclarationNameSpace get nameSpace => _nameSpace;

  @override
  void buildScopes(LibraryBuilder coreLibrary) {
    _constructorBuilders = [];
    _memberBuilders = [];
    _nameSpace = nameSpaceBuilder.buildNameSpace(
      loader: libraryBuilder.loader,
      problemReporting: libraryBuilder,
      enclosingLibraryBuilder: libraryBuilder,
      declarationBuilder: this,
      indexedLibrary: libraryBuilder.indexedLibrary,
      indexedContainer: indexedClass,
      containerType: ContainerType.Class,
      containerName: new ClassName(name),
      constructorBuilders: _constructorBuilders,
      memberBuilders: _memberBuilders,
      typeParameterFactory: libraryBuilder.typeParameterFactory,
      syntheticDeclarations: createSyntheticDeclarations(),
    );
  }

  Map<String, SyntheticDeclaration>? createSyntheticDeclarations() => null;

  bool _hasComputedSupertypes = false;

  void computeSupertypeBuilder({
    required SourceLoader loader,
    required ProblemReporting problemReporting,
    required TypeParameterFactory typeParameterFactory,
    required IndexedLibrary? indexedLibrary,
    required Map<SourceClassBuilder, TypeBuilder> mixinApplications,
    required void Function(SourceClassBuilder) addAnonymousMixinClassBuilder,
  }) {
    assert(!_hasComputedSupertypes, "Supertypes have already been computed.");
    _hasComputedSupertypes = true;
    _supertypeBuilder = _applyMixins(
      typeParameterFactory: typeParameterFactory,
      extensionScope: _introductory.extensionScope,
      compilationUnitScope: _introductory.compilationUnitScope,
      problemReporting: problemReporting,
      objectTypeBuilder: loader.target.objectType,
      enclosingLibraryBuilder: libraryBuilder,
      fileUri: _introductory.fileUri,
      indexedLibrary: indexedLibrary,
      supertype: _introductory.supertype,
      mixins: _introductory.mixedInTypes,
      mixinApplications: mixinApplications,
      startOffset: _introductory.startOffset,
      nameOffset: _introductory.nameOffset,
      endOffset: _introductory.endOffset,
      subclassName: _introductory.name,
      isMixinDeclaration: _introductory.isMixinDeclaration,
      typeParameters: typeParameters,
      modifiers: Modifiers.empty,
      onAnonymousMixin: (SourceClassBuilder anonymousMixinBuilder) {
        Reference? reference = anonymousMixinBuilder.indexedClass?.reference;
        if (reference != null) {
          loader.referenceMap.registerNamedBuilder(
            reference,
            anonymousMixinBuilder,
          );
        }
        addAnonymousMixinClassBuilder(anonymousMixinBuilder);
        anonymousMixinBuilder.buildScopes(loader.coreLibrary);
      },
    );
    _interfaceBuilders = _introductory.interfaces;
  }

  void markAsCyclic(ClassBuilder objectClass) {
    assert(
      _hasComputedSupertypes,
      "Supertype of $this has not been computed yet.",
    );

    // Ensure that the cycle is broken by removing superclass and
    // implemented interfaces.
    cls.implementedTypes.clear();
    cls.supertype = null;
    cls.mixedInType = null;
    _supertypeBuilder = new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
      objectClass,
      const NullabilityBuilder.omitted(),
      instanceTypeParameterAccess: InstanceTypeParameterAccessState.Unexpected,
    );
    _interfaceBuilders = null;
    _mixedInTypeBuilder = null;

    // TODO(johnniwinther): Update the message for when a class depends on
    // a cycle but does not depend on itself.
    libraryBuilder.addProblem(
      diag.cyclicClassHierarchy.withArguments(typeName: fullNameForErrors),
      fileOffset,
      noLength,
      fileUri,
    );
  }

  // Coverage-ignore(suite): Not run.
  /// Check that this class, which is the `Object` class,  has no supertypes.
  /// Recover by removing any found.
  void checkObjectSupertypes() {
    if (_supertypeBuilder != null) {
      _supertypeBuilder = null;
      libraryBuilder.addProblem(
        diag.objectExtends,
        fileOffset,
        noLength,
        fileUri,
      );
    }
    if (_interfaceBuilders != null) {
      libraryBuilder.addProblem(
        diag.objectImplements,
        fileOffset,
        noLength,
        fileUri,
      );
      _interfaceBuilders = null;
    }
    if (_mixedInTypeBuilder != null) {
      libraryBuilder.addProblem(
        diag.objectMixesIn,
        fileOffset,
        noLength,
        fileUri,
      );
      _mixedInTypeBuilder = null;
    }
  }

  void installDefaultSupertypes(
    ClassBuilder objectClassBuilder,
    Class objectClass,
  ) {
    if (objectClass != cls) {
      cls.supertype ??= objectClass.asRawSupertype;
      _supertypeBuilder ??= new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
        objectClassBuilder,
        const NullabilityBuilder.omitted(),
        instanceTypeParameterAccess:
            InstanceTypeParameterAccessState.Unexpected,
      );
    }
    if (isMixinApplication) {
      cls.mixedInType = mixedInTypeBuilder!.buildMixedInType(libraryBuilder);
    }
  }

  @override
  TypeBuilder? get supertypeBuilder {
    assert(
      _hasComputedSupertypes,
      "Supertype of $this has not been computed yet.",
    );
    return _supertypeBuilder;
  }

  @override
  SourceLibraryBuilder get parent => libraryBuilder;

  void _buildMemberOutlineNodes(SourceMemberBuilder memberBuilder) {
    assert(
      memberBuilder.parent == this,
      "Unexpected member $memberBuilder from outside $this.",
    );
    memberBuilder.buildOutlineNodes(({
      required Member member,
      Member? tearOff,
      required BuiltMemberKind kind,
    }) {
      _addMemberToClass(memberBuilder, member);
      if (tearOff != null) {
        _addMemberToClass(memberBuilder, tearOff);
      }
    });
  }

  Class build(LibraryBuilder coreLibrary) {
    _memberBuilders.forEach(_buildMemberOutlineNodes);
    _constructorBuilders.forEach(_buildMemberOutlineNodes);

    if (_supertypeBuilder != null) {
      _supertypeBuilder = _checkSupertype(_supertypeBuilder!);
    }
    TypeDeclarationBuilder? supertypeDeclaration = supertypeBuilder
        ?.computeUnaliasedDeclaration(isUsedAsClass: false);
    if (LibraryBuilder.isFunction(supertypeDeclaration, coreLibrary)) {
      _supertypeBuilder = null;
    }
    Supertype? supertype = supertypeBuilder?.buildSupertype(
      libraryBuilder,
      isMixinDeclaration ? TypeUse.mixinOnType : TypeUse.classExtendsType,
    );
    if (!isMixinDeclaration &&
        cls.supertype != null &&
        // Coverage-ignore(suite): Not run.
        cls.superclass!.isMixinDeclaration) {
      // Coverage-ignore-block(suite): Not run.
      // Declared mixins have interfaces that can be implemented, but they
      // cannot be extended.  However, a mixin declaration with a single
      // superclass constraint is encoded with the constraint as the supertype,
      // and that is allowed to be a mixin's interface.
      libraryBuilder.addProblem(
        diag.supertypeIsIllegal.withArguments(typeName: cls.superclass!.name),
        fileOffset,
        noLength,
        fileUri,
      );
      supertype = null;
    }
    if (supertype == null && _supertypeBuilder is! NamedTypeBuilder) {
      _supertypeBuilder = null;
    }
    cls.supertype = supertype;

    if (_mixedInTypeBuilder != null) {
      _mixedInTypeBuilder = _checkSupertype(_mixedInTypeBuilder!);
    }
    TypeDeclarationBuilder? mixedInDeclaration = _mixedInTypeBuilder
        ?.computeUnaliasedDeclaration(isUsedAsClass: false);
    if (LibraryBuilder.isFunction(mixedInDeclaration, coreLibrary)) {
      _mixedInTypeBuilder = null;
      cls.isAnonymousMixin = false;
    }
    Supertype? mixedInType = _mixedInTypeBuilder?.buildMixedInType(
      libraryBuilder,
    );

    cls.isMixinDeclaration = isMixinDeclaration;
    cls.mixedInType = mixedInType;

    // TODO(ahe): If `cls.supertype` is null, and this isn't Object, report a
    // compile-time error.
    cls.isAbstract = isAbstract;
    cls.isMixinClass = isMixinClass;
    cls.isSealed = isSealed;
    cls.isBase = isBase;
    cls.isInterface = isInterface;
    cls.isFinal = isFinal;

    List<TypeBuilder>? interfaceBuilders = this.interfaceBuilders;
    if (interfaceBuilders != null) {
      for (int i = 0; i < interfaceBuilders.length; ++i) {
        interfaceBuilders[i] = _checkSupertype(interfaceBuilders[i]);
        TypeDeclarationBuilder? implementedDeclaration = interfaceBuilders[i]
            .computeUnaliasedDeclaration(isUsedAsClass: false);
        if (LibraryBuilder.isFunction(implementedDeclaration, coreLibrary) &&
            // Allow wasm to implement `Function`.
            !libraryBuilder.mayImplementRestrictedTypes) {
          continue;
        }
        Supertype? supertype = interfaceBuilders[i].buildSupertype(
          libraryBuilder,
          TypeUse.classImplementsType,
        );
        if (supertype != null) {
          // TODO(ahe): Report an error if supertype is null.
          cls.implementedTypes.add(supertype);
        }
      }
    }

    cls.procedures.sort(compareProcedures);
    return cls;
  }

  @override
  List<TypeBuilder>? get interfaceBuilders {
    assert(_hasComputedSupertypes, "Interfaces have not been computed yet.");
    return _interfaceBuilders;
  }

  @override
  TypeBuilder? get mixedInTypeBuilder => _mixedInTypeBuilder;

  void setInferredMixedInTypeArguments(List<TypeBuilder> typeArguments) {
    InterfaceType mixedInType = cls.mixedInType!.asInterfaceType;
    TypeBuilder mixedInTypeBuilder = _mixedInTypeBuilder!;
    _mixedInTypeBuilder = new NamedTypeBuilderImpl.forDartType(
      mixedInType,
      mixedInTypeBuilder.declaration!,
      new NullabilityBuilder.fromNullability(Nullability.nonNullable),
      arguments: typeArguments,
      fileUri: mixedInTypeBuilder.fileUri,
      charOffset: mixedInTypeBuilder.charOffset,
    );
    libraryBuilder.registerBoundsCheck(
      mixedInType,
      mixedInTypeBuilder.fileUri!,
      mixedInTypeBuilder.charOffset!,
      TypeUse.classWithType,
      inferred: true,
    );
  }

  BodyBuilderContext createBodyBuilderContext() {
    return new ClassBodyBuilderContext(this);
  }

  void buildOutlineExpressions(
    ClassHierarchy classHierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    void build(SourceMemberBuilder declaration) {
      declaration.buildOutlineExpressions(
        classHierarchy,
        delayedDefaultValueCloners,
      );
    }

    BodyBuilderContext bodyBuilderContext = createBodyBuilderContext();
    _introductory.buildOutlineExpressions(
      annotatable: cls,
      annotatableFileUri: cls.fileUri,
      bodyBuilderContext: bodyBuilderContext,
      libraryBuilder: libraryBuilder,
      classHierarchy: classHierarchy,
      createFileUriExpression: false,
    );
    for (int i = 0; i < _augmentations.length; i++) {
      ClassDeclaration augmentation = _augmentations[i];
      augmentation.buildOutlineExpressions(
        annotatable: cls,
        annotatableFileUri: cls.fileUri,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        libraryBuilder: libraryBuilder,
        createFileUriExpression: true,
      );
    }
    if (typeParameters != null) {
      for (int i = 0; i < typeParameters!.length; i++) {
        typeParameters![i].buildOutlineExpressions(
          libraryBuilder,
          bodyBuilderContext,
          classHierarchy,
        );
      }
    }

    filteredConstructorsIterator<SourceMemberBuilder>(
      includeDuplicates: false,
    ).forEach(build);
    filteredMembersIterator<SourceMemberBuilder>(
      includeDuplicates: false,
    ).forEach(build);
  }

  /// Looks up the constructor by [name] on the class built by this class
  /// builder.
  SourceConstructorBuilder? lookupConstructor(Name name) {
    if (name.text == "new") {
      name = new Name("", name.library);
    }

    Builder? builder = nameSpace.lookupConstructor(name.text)?.getable;
    if (builder is SourceConstructorBuilder) {
      return builder;
    }
    return null;
  }

  /// Looks up the super constructor by [name] on the superclass of the class
  /// built by this class builder.
  MemberLookupResult? lookupSuperConstructor(
    String name,
    LibraryBuilder accessingLibrary,
  ) {
    TypeDeclarationBuilder? typeDeclarationBuilder = supertypeBuilder
        ?.computeUnaliasedDeclaration(isUsedAsClass: true);
    if (typeDeclarationBuilder is DeclarationBuilder) {
      return typeDeclarationBuilder.findConstructorOrFactory(
        name,
        accessingLibrary,
      );
    } else if (typeDeclarationBuilder is InvalidBuilder) {
      return new InvalidMemberLookupResult(typeDeclarationBuilder.message);
    }
    return null;
  }

  /// Returns a map which maps the type parameters of [superclass] to their
  /// respective values as defined by the superclass clause of this class (and
  /// its superclasses).
  ///
  /// It's assumed that [superclass] is a superclass of this class.
  ///
  /// For example, given:
  ///
  ///     class Box<T> {}
  ///     class BeatBox extends Box<Beat> {}
  ///     class Beat {}
  ///
  /// We have:
  ///
  ///     [[BeatBox]].getSubstitutionMap([[Box]]) -> {[[Box::T]]: Beat]]}.
  ///
  /// It's an error if [superclass] isn't a superclass.
  Map<TypeParameter, DartType> getSubstitutionMap(Class superclass) {
    Supertype? supertype = cls.supertype;
    Map<TypeParameter, DartType> substitutionMap = <TypeParameter, DartType>{};
    List<DartType> arguments;
    List<TypeParameter> variables;
    Class? classNode;

    while (classNode != superclass) {
      classNode = supertype!.classNode;
      arguments = supertype.typeArguments;
      variables = classNode.typeParameters;
      supertype = classNode.supertype;
      if (variables.isNotEmpty) {
        Map<TypeParameter, DartType> directSubstitutionMap =
            <TypeParameter, DartType>{};
        for (int i = 0; i < variables.length; i++) {
          DartType argument = i < arguments.length
              ? arguments[i]
              : const DynamicType();
          // TODO(ahe): Investigate if requiring the caller to use
          // `substituteDeep` from `package:kernel/type_algebra.dart` instead
          // of `substitute` is faster. If so, we can simply this code.
          argument = substitute(argument, substitutionMap);
          directSubstitutionMap[variables[i]] = argument;
        }
        substitutionMap = directSubstitutionMap;
      }
    }

    return substitutionMap;
  }

  void checkSupertypes(
    CoreTypes coreTypes,
    ClassHierarchyBuilder hierarchyBuilder,
    Class objectClass,
    Class enumClass,
    Class underscoreEnumClass,
  ) {
    // This method determines whether the class (that's being built) its super
    // class appears both in 'extends' and 'implements' clauses and whether any
    // interface appears multiple times in the 'implements' clause.
    // Moreover, it checks that `FutureOr` and `void` are not among the
    // supertypes and that `Enum` is not implemented by non-abstract classes.

    // Anonymous mixins have to propagate certain class modifiers.
    if (cls.isAnonymousMixin) {
      Class? superclass = cls.superclass;
      Class? mixedInClass = cls.mixedInClass;
      // If either [superclass] or [mixedInClass] is sealed, the current
      // anonymous mixin is sealed.
      if (superclass != null && superclass.isSealed ||
          mixedInClass != null && mixedInClass.isSealed) {
        cls.isSealed = true;
      } else {
        // Otherwise, if either [superclass] or [mixedInClass] is base or final,
        // then the current anonymous mixin is final.
        bool superclassIsBaseOrFinal =
            superclass != null && (superclass.isBase || superclass.isFinal);
        bool mixedInClassIsBaseOrFinal =
            mixedInClass != null &&
            (mixedInClass.isBase || mixedInClass.isFinal);
        if (superclassIsBaseOrFinal || mixedInClassIsBaseOrFinal) {
          cls.isFinal = true;
        }
      }
    }

    ClassHierarchyNode classHierarchyNode = hierarchyBuilder.getNodeFromClass(
      cls,
    );
    if (libraryBuilder.libraryFeatures.enhancedEnums.isEnabled && !isEnum) {
      bool hasEnumSuperinterface = false;
      const List<String> restrictedNames = ["index", "hashCode", "=="];
      Map<String, ClassBuilder> restrictedMembersInSuperclasses = {};
      ClassBuilder? superclassDeclaringConcreteValues;
      List<Supertype> interfaces = classHierarchyNode.superclasses;
      for (int i = 0; !hasEnumSuperinterface && i < interfaces.length; i++) {
        Class interfaceClass = interfaces[i].classNode;
        if (interfaceClass == enumClass) {
          hasEnumSuperinterface = true;
        }

        if (!interfaceClass.isEnum &&
            interfaceClass != objectClass &&
            interfaceClass != underscoreEnumClass) {
          ClassHierarchyNode superclassHierarchyNode = hierarchyBuilder
              .getNodeFromClass(interfaceClass);
          for (String restrictedMemberName in restrictedNames) {
            // TODO(johnniwinther): Handle injected members.
            Builder? member = superclassHierarchyNode.classBuilder
                .lookupLocalMember(restrictedMemberName)
                ?.getable;
            if (member is PropertyBuilder && !member.hasAbstractGetter ||
                member is MethodBuilder && !member.isAbstract) {
              restrictedMembersInSuperclasses[restrictedMemberName] ??=
                  superclassHierarchyNode.classBuilder;
            }
          }
          Builder? member = superclassHierarchyNode.classBuilder
              .lookupLocalMember("values")
              ?.getable;
          if (member is MemberBuilder &&
              (member is PropertyBuilder && !member.hasAbstractGetter ||
                  // Coverage-ignore(suite): Not run.
                  member is MethodBuilder && !member.isAbstract)) {
            superclassDeclaringConcreteValues ??= member.classBuilder;
          }
        }
      }
      interfaces = classHierarchyNode.interfaces;
      for (int i = 0; !hasEnumSuperinterface && i < interfaces.length; i++) {
        if (interfaces[i].classNode == enumClass) {
          hasEnumSuperinterface = true;
        }
      }
      if (!cls.isAbstract && !cls.isEnum && hasEnumSuperinterface) {
        libraryBuilder.addProblem(
          diag.enumSupertypeOfNonAbstractClass.withArguments(className: name),
          fileOffset,
          noLength,
          fileUri,
        );
      }

      if (hasEnumSuperinterface && cls != underscoreEnumClass) {
        // Instance members named `values` are restricted.
        LookupResult? result = nameSpace.lookup("values");
        NamedBuilder? customValuesDeclaration = result?.getable;
        if (customValuesDeclaration != null &&
            !customValuesDeclaration.isStatic) {
          // Retrieve the earliest declaration for error reporting.
          while (customValuesDeclaration?.next != null) {
            // Coverage-ignore-block(suite): Not run.
            customValuesDeclaration = customValuesDeclaration?.next;
          }
          Uri fileUri = customValuesDeclaration!.fileUri!;
          int fileOffset = customValuesDeclaration.fileOffset;
          int length = customValuesDeclaration.fullNameForErrors.length;
          if (customValuesDeclaration is PropertyBuilder) {
            UriOffsetLength uriOffset =
                customValuesDeclaration.getterUriOffset!;
            fileUri = uriOffset.fileUri;
            fileOffset = uriOffset.fileOffset;
            length = uriOffset.length;
          }
          libraryBuilder.addProblem(
            diag.enumImplementerContainsValuesDeclaration.withArguments(
              className: this.name,
            ),
            fileOffset,
            length,
            fileUri,
          );
        }
        customValuesDeclaration = result?.setable;
        if (customValuesDeclaration != null &&
            !customValuesDeclaration.isStatic) {
          // Retrieve the earliest declaration for error reporting.
          while (customValuesDeclaration?.next != null) {
            // Coverage-ignore-block(suite): Not run.
            customValuesDeclaration = customValuesDeclaration?.next;
          }
          Uri fileUri = customValuesDeclaration!.fileUri!;
          int fileOffset = customValuesDeclaration.fileOffset;
          int length = customValuesDeclaration.fullNameForErrors.length;
          if (customValuesDeclaration is PropertyBuilder) {
            UriOffsetLength uriOffset =
                customValuesDeclaration.setterUriOffset!;
            fileUri = uriOffset.fileUri;
            fileOffset = uriOffset.fileOffset;
            length = uriOffset.length;
          }
          libraryBuilder.addProblem(
            diag.enumImplementerContainsValuesDeclaration.withArguments(
              className: this.name,
            ),
            fileOffset,
            length,
            fileUri,
          );
        }
        if (superclassDeclaringConcreteValues != null) {
          libraryBuilder.addProblem(
            diag.inheritedRestrictedMemberOfEnumImplementer.withArguments(
              memberName: "values",
              superclassName: superclassDeclaringConcreteValues.name,
            ),
            fileOffset,
            noLength,
            fileUri,
          );
        }

        // Non-setter concrete instance members named `index` and hashCode and
        // operator == are restricted.
        for (String restrictedMemberName in restrictedNames) {
          Builder? member = nameSpace.lookup(restrictedMemberName)?.getable;
          if (member is MemberBuilder &&
              (member is PropertyBuilder && !member.hasAbstractGetter ||
                  member is MethodBuilder && !member.isAbstract)) {
            libraryBuilder.addProblem(
              diag.enumImplementerContainsRestrictedInstanceDeclaration
                  .withArguments(
                    className: this.name,
                    memberName: restrictedMemberName,
                  ),
              member.fileOffset,
              member.fullNameForErrors.length,
              fileUri,
            );
          }

          if (restrictedMembersInSuperclasses.containsKey(
            restrictedMemberName,
          )) {
            ClassBuilder restrictedNameMemberProvider =
                restrictedMembersInSuperclasses[restrictedMemberName]!;
            libraryBuilder.addProblem(
              diag.inheritedRestrictedMemberOfEnumImplementer.withArguments(
                memberName: restrictedMemberName,
                superclassName: restrictedNameMemberProvider.name,
              ),
              fileOffset,
              noLength,
              fileUri,
            );
          }
        }
      }
    }

    void fail(
      TypeBuilder target,
      Message message,
      TypeDeclarationBuilder? aliasBuilder,
    ) {
      int nameOffset = target.typeName!.nameOffset;
      int nameLength = target.typeName!.nameLength;
      if (aliasBuilder is TypeAliasBuilder) {
        // Coverage-ignore-block(suite): Not run.
        libraryBuilder.addProblem(
          message,
          nameOffset,
          nameLength,
          target.fileUri,
          context: [
            diag.typedefCause.withLocation(
              aliasBuilder.fileUri,
              aliasBuilder.fileOffset,
              noLength,
            ),
          ],
        );
      } else {
        libraryBuilder.addProblem(
          message,
          nameOffset,
          nameLength,
          target.fileUri,
        );
      }
    }

    // Extract and check superclass (if it exists).
    ClassBuilder? superClass;
    TypeBuilder? superClassType = supertypeBuilder;
    if (superClassType != null) {
      TypeDeclarationBuilder? superDeclaration = superClassType.declaration;
      TypeDeclarationBuilder? unaliasedSuperDeclaration = superClassType
          .computeUnaliasedDeclaration(isUsedAsClass: true);
      // TODO(eernst): Should gather 'restricted supertype' checks in one place,
      // e.g., dynamic/int/String/Null and more are checked elsewhere.
      if (unaliasedSuperDeclaration is NeverTypeDeclarationBuilder) {
        fail(superClassType, diag.extendsNever, superDeclaration);
      } else if (unaliasedSuperDeclaration is ClassBuilder) {
        superClass = unaliasedSuperDeclaration;
      }
    }
    if (cls.isMixinClass) {
      // Check that the class does not have a constructor.
      Iterator<SourceMemberBuilder> constructorIterator =
          filteredConstructorsIterator(includeDuplicates: false);
      while (constructorIterator.moveNext()) {
        SourceMemberBuilder constructor = constructorIterator.current;
        // Assumes the constructor isn't synthetic since
        // [installSyntheticConstructors] hasn't been called yet.
        if (constructor is SourceConstructorBuilder) {
          // Report an error if a mixin class has a constructor with parameters,
          // is external, or is a redirecting constructor.
          if (constructor.isEffectivelyRedirecting ||
              constructor.hasParameters ||
              constructor.isEffectivelyExternal) {
            libraryBuilder.addProblem(
              diag.illegalMixinDueToConstructors.withArguments(
                className: fullNameForErrors,
              ),
              constructor.fileOffset,
              noLength,
              constructor.fileUri,
            );
          }
        }
      }
      // Check that the class has 'Object' as their superclass.
      if (superClass != null &&
          superClassType != null &&
          superClass.cls != objectClass) {
        libraryBuilder.addProblem(
          diag.mixinInheritsFromNotObject.withArguments(className: name),
          superClassType.charOffset ?? TreeNode.noOffset,
          noLength,
          superClassType.fileUri ?? // Coverage-ignore(suite): Not run.
              fileUri,
        );
      }
    }
    if (classHierarchyNode.isMixinApplication) {
      assert(
        _mixedInTypeBuilder != null,
        "No mixed in type builder for mixin application $this.",
      );
      ClassHierarchyNode mixedInNode = classHierarchyNode.mixedInNode!;
      ClassHierarchyNode? mixinSuperClassNode =
          mixedInNode.directSuperClassNode;
      if (mixinSuperClassNode != null &&
          mixinSuperClassNode.classBuilder.cls != objectClass &&
          !mixedInNode.classBuilder.cls.isMixinDeclaration) {
        libraryBuilder.addProblem(
          diag.mixinInheritsFromNotObject.withArguments(
            className: mixedInNode.classBuilder.name,
          ),
          _mixedInTypeBuilder!.charOffset ?? TreeNode.noOffset,
          noLength,
          _mixedInTypeBuilder!.fileUri ?? // Coverage-ignore(suite): Not run.
              fileUri,
        );
      }
    }

    if (interfaceBuilders == null) return;

    // Validate interfaces.
    Map<ClassBuilder, int>? problems;
    Map<ClassBuilder, int>? problemsOffsets;
    Set<ClassBuilder> implemented = new Set<ClassBuilder>();
    for (TypeBuilder type in interfaceBuilders!) {
      TypeDeclarationBuilder? typeDeclaration = type.declaration;
      TypeDeclarationBuilder? unaliasedDeclaration = type
          .computeUnaliasedDeclaration(isUsedAsClass: true);
      if (unaliasedDeclaration is ClassBuilder) {
        ClassBuilder interface = unaliasedDeclaration;
        if (superClass == interface) {
          libraryBuilder.addProblem(
            diag.implementsSuperClass.withArguments(name: interface.name),
            this.fileOffset,
            noLength,
            this.fileUri,
          );
        } else if (interface.cls.name == "FutureOr" &&
            interface.cls.enclosingLibrary.importUri.isScheme("dart") &&
            interface.cls.enclosingLibrary.importUri.path == "async") {
          libraryBuilder.addProblem(
            diag.implementsFutureOr,
            this.fileOffset,
            noLength,
            this.fileUri,
          );
        } else if (implemented.contains(interface)) {
          // Aggregate repetitions.
          problems ??= <ClassBuilder, int>{};
          problems[interface] ??= 0;
          problems[interface] = problems[interface]! + 1;
          problemsOffsets ??= <ClassBuilder, int>{};
          problemsOffsets[interface] ??= type.charOffset ?? TreeNode.noOffset;
        } else {
          implemented.add(interface);
        }
      }
      if (unaliasedDeclaration != superClass) {
        // TODO(eernst): Have all 'restricted supertype' checks in one place.
        if (unaliasedDeclaration is NeverTypeDeclarationBuilder) {
          fail(type, diag.implementsNever, typeDeclaration);
        }
      }
    }
    if (problems != null) {
      problems.forEach((ClassBuilder interface, int repetitions) {
        libraryBuilder.addProblem(
          diag.implementsRepeated.withArguments(
            name: interface.name,
            extraCount: repetitions,
          ),
          problemsOffsets![interface]!,
          noLength,
          fileUri,
        );
      });
    }
  }

  void checkMixinApplication(ClassHierarchy hierarchy, CoreTypes coreTypes) {
    TypeEnvironment typeEnvironment = new TypeEnvironment(coreTypes, hierarchy);
    // A mixin declaration can only be applied to a class that implements all
    // the declaration's superclass constraints.
    InterfaceType supertype = cls.supertype!.asInterfaceType;
    Substitution substitution = Substitution.fromSupertype(cls.mixedInType!);
    for (Supertype constraint in cls.mixedInClass!.onClause) {
      InterfaceType requiredInterface = substitution
          .substituteSupertype(constraint)
          .asInterfaceType;
      InterfaceType? implementedInterface = hierarchy
          .getInterfaceTypeAsInstanceOfClass(
            supertype,
            requiredInterface.classNode,
          );
      if (implementedInterface == null ||
          !typeEnvironment.areMutualSubtypes(
            implementedInterface,
            requiredInterface,
          )) {
        libraryBuilder.addProblem(
          diag.mixinApplicationIncompatibleSupertype.withArguments(
            supertype: supertype,
            requiredInterfaceType: requiredInterface,
            mixedInType: cls.mixedInType!.asInterfaceType,
          ),
          cls.fileOffset,
          noLength,
          cls.fileUri,
        );
      }
    }
  }

  void checkRedirectingFactories(TypeEnvironment typeEnvironment) {
    Iterator<SourceFactoryBuilder> iterator = filteredConstructorsIterator(
      includeDuplicates: true,
    );
    while (iterator.moveNext()) {
      iterator.current.checkRedirectingFactories(typeEnvironment);
    }
  }

  Map<String, ConstructorRedirection>? _redirectingConstructors;

  /// Registers a constructor redirection for this class and returns true if
  /// this redirection gives rise to a cycle that has not been reported before.
  bool checkConstructorCyclic(String source, String target) {
    ConstructorRedirection? redirect = new ConstructorRedirection(target);
    _redirectingConstructors ??= <String, ConstructorRedirection>{};
    _redirectingConstructors![source] = redirect;
    while (redirect != null) {
      if (redirect.cycleReported) return false;
      if (redirect.target == source) {
        redirect.cycleReported = true;
        return true;
      }
      redirect = _redirectingConstructors![redirect.target];
    }
    return false;
  }

  TypeBuilder _checkSupertype(TypeBuilder supertype) {
    if (typeParameters == null) return supertype;
    Message? message;
    for (int i = 0; i < typeParameters!.length; ++i) {
      NominalParameterBuilder typeParameterBuilder = typeParameters![i];
      Variance variance = supertype
          .computeTypeParameterBuilderVariance(
            typeParameterBuilder,
            sourceLoader: libraryBuilder.loader,
          )
          .variance!;
      if (!variance.greaterThanOrEqual(typeParameters![i].variance)) {
        if (typeParameters![i].parameter.isLegacyCovariant) {
          message = diag.invalidTypeParameterInSupertype.withArguments(
            typeVariableName: typeParameters![i].name,
            useVariance: variance.keyword,
            supertypeName: supertype.typeName!.name,
          );
        } else {
          message = diag.invalidTypeParameterInSupertypeWithVariance
              .withArguments(
                typeVariableVariance: typeParameters![i].variance.keyword,
                typeVariableName: typeParameters![i].name,
                useVariance: variance.keyword,
                supertypeName: supertype.typeName!.name,
              );
        }
        libraryBuilder.addProblem(message, fileOffset, noLength, fileUri);
      }
    }
    if (message != null) {
      TypeName typeName = supertype.typeName!;
      return new NamedTypeBuilderImpl(
        typeName,
        const NullabilityBuilder.omitted(),
        fileUri: fileUri,
        charOffset: fileOffset,
        instanceTypeParameterAccess:
            InstanceTypeParameterAccessState.Unexpected,
      )..bind(
        libraryBuilder,
        new InvalidBuilder(
          typeName.name,
          message.withLocation(fileUri, fileOffset, noLength),
        ),
      );
    }
    return supertype;
  }

  void checkVarianceInField(
    TypeEnvironment typeEnvironment, {
    required DartType fieldType,
    required bool isInstanceMember,
    required bool hasSetter,
    required bool isCovariantByDeclaration,
    required Uri fileUri,
    required int fileOffset,
  }) {
    List<TypeParameter> typeParameters = cls.typeParameters;
    if (typeParameters.isNotEmpty) {
      for (TypeParameter typeParameter in typeParameters) {
        Variance fieldVariance = computeVariance(typeParameter, fieldType);
        if (isInstanceMember) {
          reportVariancePositionIfInvalid(
            fieldVariance,
            typeParameter,
            fileUri,
            fileOffset,
          );
        }
        if (isInstanceMember && hasSetter && !isCovariantByDeclaration) {
          fieldVariance = Variance.contravariant.combine(fieldVariance);
          reportVariancePositionIfInvalid(
            fieldVariance,
            typeParameter,
            fileUri,
            fileOffset,
          );
        }
      }
    }
  }

  void checkVarianceInTypeParameters(
    TypeEnvironment typeEnvironment,
    List<SourceNominalParameterBuilder>? typeParameters,
  ) {
    List<TypeParameter> classTypeParameters = cls.typeParameters;
    if (typeParameters != null && classTypeParameters.isNotEmpty) {
      for (NominalParameterBuilder nominalParameter in typeParameters) {
        for (TypeParameter classTypeParameter in classTypeParameters) {
          Variance typeVariance = Variance.invariant.combine(
            computeVariance(
              classTypeParameter,
              nominalParameter.parameter.bound,
            ),
          );
          reportVariancePositionIfInvalid(
            typeVariance,
            classTypeParameter,
            fileUri,
            nominalParameter.fileOffset,
          );
        }
      }
    }
  }

  void checkVarianceInFormals(
    TypeEnvironment type,
    List<FormalParameterBuilder>? formals,
  ) {
    List<TypeParameter> classTypeParameters = cls.typeParameters;
    if (formals != null && classTypeParameters.isNotEmpty) {
      for (FormalParameterBuilder formal in formals) {
        if (!formal.isCovariantByDeclaration) {
          for (TypeParameter typeParameter in classTypeParameters) {
            Variance formalVariance = Variance.contravariant.combine(
              computeVariance(typeParameter, formal.variable!.type),
            );
            reportVariancePositionIfInvalid(
              formalVariance,
              typeParameter,
              formal.fileUri,
              formal.fileOffset,
            );
          }
        }
      }
    }
  }

  void checkVarianceInReturnType(
    TypeEnvironment type,
    DartType returnType, {
    required Uri fileUri,
    required fileOffset,
  }) {
    List<TypeParameter> classTypeParameters = cls.typeParameters;
    if (classTypeParameters.isNotEmpty) {
      for (TypeParameter typeParameter in classTypeParameters) {
        Variance returnTypeVariance = computeVariance(
          typeParameter,
          returnType,
        );
        reportVariancePositionIfInvalid(
          returnTypeVariance,
          typeParameter,
          fileUri,
          fileOffset,
          isReturnType: true,
        );
      }
    }
  }

  // Coverage-ignore(suite): Not run.
  void checkVarianceInFunction(
    Procedure procedure,
    TypeEnvironment typeEnvironment,
    List<TypeParameter> typeParameters,
  ) {
    List<TypeParameter> functionTypeParameters =
        procedure.function.typeParameters;
    List<VariableDeclaration> positionalParameters =
        procedure.function.positionalParameters;
    List<VariableDeclaration> namedParameters =
        procedure.function.namedParameters;
    DartType returnType = procedure.function.returnType;

    for (TypeParameter functionParameter in functionTypeParameters) {
      for (TypeParameter typeParameter in typeParameters) {
        Variance typeVariance = Variance.invariant.combine(
          computeVariance(typeParameter, functionParameter.bound),
        );
        reportVariancePositionIfInvalid(
          typeVariance,
          typeParameter,
          fileUri,
          functionParameter.fileOffset,
        );
      }
    }
    for (VariableDeclaration formal in positionalParameters) {
      if (!formal.isCovariantByDeclaration) {
        for (TypeParameter typeParameter in typeParameters) {
          Variance formalVariance = Variance.contravariant.combine(
            computeVariance(typeParameter, formal.type),
          );
          reportVariancePositionIfInvalid(
            formalVariance,
            typeParameter,
            fileUri,
            formal.fileOffset,
          );
        }
      }
    }
    for (VariableDeclaration named in namedParameters) {
      for (TypeParameter typeParameter in typeParameters) {
        Variance namedVariance = Variance.contravariant.combine(
          computeVariance(typeParameter, named.type),
        );
        reportVariancePositionIfInvalid(
          namedVariance,
          typeParameter,
          fileUri,
          named.fileOffset,
        );
      }
    }

    for (TypeParameter typeParameter in typeParameters) {
      Variance returnTypeVariance = computeVariance(typeParameter, returnType);
      reportVariancePositionIfInvalid(
        returnTypeVariance,
        typeParameter,
        fileUri,
        procedure.function.fileOffset,
        isReturnType: true,
      );
    }
  }

  void reportVariancePositionIfInvalid(
    Variance variance,
    TypeParameter typeParameter,
    Uri fileUri,
    int fileOffset, {
    bool isReturnType = false,
  }) {
    ProblemReporting problemReporting = libraryBuilder;
    if (!typeParameter.isLegacyCovariant &&
        !variance.greaterThanOrEqual(typeParameter.variance)) {
      Message message;
      if (isReturnType) {
        message = diag.invalidTypeParameterVariancePositionInReturnType
            .withArguments(
              typeVariableVariance: typeParameter.variance.keyword,
              typeVariableName: typeParameter.name!,
              useVariance: variance.keyword,
            );
      } else {
        message = diag.invalidTypeParameterVariancePosition.withArguments(
          typeVariableVariance: typeParameter.variance.keyword,
          typeVariableName: typeParameter.name!,
          useVariance: variance.keyword,
        );
      }
      problemReporting.reportTypeArgumentIssue(
        message: message,
        fileUri: fileUri,
        fileOffset: fileOffset,
        typeParameter: typeParameter,
      );
    }
  }

  void addSyntheticConstructor(SourceConstructorBuilder constructorBuilder) {
    String name = constructorBuilder.name;
    assert(
      nameSpace.lookupConstructor(name) == null,
      "Unexpected existing constructor when adding synthetic constructor "
      "$constructorBuilder to $this.",
    );
    addConstructorInternal(constructorBuilder, addToNameSpace: true);
    _buildMemberOutlineNodes(constructorBuilder);
    if (constructorBuilder.isConst) {
      cls.hasConstConstructor = true;
    }
  }

  int buildBodyNodes() {
    int count = 0;

    void buildMembers(SourceMemberBuilder builder) {
      assert(builder.parent == this, "Unexpected member $builder in this.");
      count += builder.buildBodyNodes(
        // Coverage-ignore(suite): Not run.
        ({
          required Member member,
          Member? tearOff,
          required BuiltMemberKind kind,
        }) {
          _addMemberToClass(builder, member);
          if (tearOff != null) {
            _addMemberToClass(builder, tearOff);
          }
        },
      );
    }

    unfilteredMembersIterator.forEach(buildMembers);
    unfilteredConstructorsIterator.forEach(buildMembers);
    return count;
  }

  void _addMemberToClass(SourceMemberBuilder memberBuilder, Member member) {
    member.parent = cls;
    if (!memberBuilder.isDuplicate) {
      if (member is Procedure) {
        cls.addProcedure(member);
      } else if (member is Field) {
        cls.addField(member);
      } else if (member is Constructor) {
        cls.addConstructor(member);
      } else {
        unhandled(
          "${member.runtimeType}",
          "getMember",
          member.fileOffset,
          member.fileUri,
        );
      }
    }
  }

  /// Return a map whose keys are the supertypes of this [SourceClassBuilder]
  /// after expansion of type aliases, if any. For each supertype key, the
  /// corresponding value is the type alias which was unaliased in order to
  /// find the supertype, or null if the supertype was not aliased.
  Map<TypeDeclarationBuilder?, TypeAliasBuilder?> computeDirectSupertypes(
    ClassBuilder objectClass,
  ) {
    final Map<TypeDeclarationBuilder?, TypeAliasBuilder?> result = {};
    final TypeBuilder? supertype = this.supertypeBuilder;
    if (supertype != null) {
      TypeDeclarationBuilder? declaration = supertype.declaration;
      TypeDeclarationBuilder? unaliasedDeclaration = supertype
          .computeUnaliasedDeclaration(isUsedAsClass: true);
      result[unaliasedDeclaration] = declaration is TypeAliasBuilder
          ? declaration
          : null;
    } else if (objectClass != this) {
      result[objectClass] = null;
    }

    final List<TypeBuilder>? interfaces = interfaceBuilders;
    if (interfaces != null) {
      for (int i = 0; i < interfaces.length; i++) {
        TypeBuilder interface = interfaces[i];
        TypeDeclarationBuilder? declaration = interface.declaration;
        TypeDeclarationBuilder? unaliasedDeclaration = interface
            .computeUnaliasedDeclaration(isUsedAsClass: true);
        result[unaliasedDeclaration] = declaration is TypeAliasBuilder
            ? declaration
            : null;
      }
    }
    final TypeBuilder? mixedInTypeBuilder = _mixedInTypeBuilder;
    if (mixedInTypeBuilder != null) {
      TypeDeclarationBuilder? declaration = mixedInTypeBuilder.declaration;
      TypeDeclarationBuilder? unaliasedDeclaration = mixedInTypeBuilder
          .computeUnaliasedDeclaration(isUsedAsClass: true);
      result[unaliasedDeclaration] = declaration is TypeAliasBuilder
          ? declaration
          : null;
    }
    return result;
  }

  @override
  int compareTo(SourceClassBuilder other) {
    int result = "$fileUri".compareTo("${other.fileUri}");
    if (result != 0) return result;
    return fileOffset.compareTo(other.fileOffset);
  }

  void _handleSeenCovariant(
    ClassHierarchyMembers memberHierarchy,
    Member interfaceMember,
    bool isSetter,
    callback(Member interfaceMember, bool isSetter),
  ) {
    // When a parameter is covariant we have to check that we also
    // override the same member in all parents.
    for (Supertype supertype in interfaceMember.enclosingClass!.supers) {
      Member? member = memberHierarchy.getInterfaceMember(
        supertype.classNode,
        interfaceMember.name,
        setter: isSetter,
      );
      if (member != null) {
        callback(member, isSetter);
      }
    }
  }

  void checkOverride(
    Types types,
    ClassHierarchyMembers memberHierarchy,
    Member declaredMember,
    Member interfaceMember,
    bool isSetter,
    callback(Member interfaceMember, bool isSetter), {
    required bool isInterfaceCheck,
    required Member? localMember,
  }) {
    if (declaredMember == interfaceMember) {
      return;
    }
    Member interfaceMemberOrigin =
        interfaceMember.memberSignatureOrigin ?? interfaceMember;
    if (declaredMember is Constructor || interfaceMember is Constructor) {
      unimplemented(
        "Constructor in override check.",
        declaredMember.fileOffset,
        fileUri,
      );
    }
    if (declaredMember is Procedure && interfaceMember is Procedure) {
      if (declaredMember.kind == interfaceMember.kind) {
        if (declaredMember.kind == ProcedureKind.Method ||
            declaredMember.kind == ProcedureKind.Operator) {
          bool seenCovariant = checkMethodOverride(
            types,
            declaredMember,
            interfaceMember,
            interfaceMemberOrigin,
            isInterfaceCheck,
            localMember: localMember,
          );
          if (seenCovariant) {
            _handleSeenCovariant(
              memberHierarchy,
              interfaceMember,
              isSetter,
              callback,
            );
          }
        } else if (declaredMember.kind == ProcedureKind.Getter) {
          checkGetterOverride(
            types,
            declaredMember,
            interfaceMember,
            interfaceMemberOrigin,
            isInterfaceCheck,
            localMember: localMember,
          );
        } else if (declaredMember.kind == ProcedureKind.Setter) {
          bool seenCovariant = checkSetterOverride(
            types,
            declaredMember,
            interfaceMember,
            interfaceMemberOrigin,
            isInterfaceCheck,
            localMember: localMember,
          );
          if (seenCovariant) {
            _handleSeenCovariant(
              memberHierarchy,
              interfaceMember,
              isSetter,
              callback,
            );
          }
        } else {
          // Coverage-ignore-block(suite): Not run.
          assert(
            false,
            "Unexpected procedure kind in override check: "
            "${declaredMember.kind}",
          );
        }
      }
    } else {
      bool declaredMemberHasGetter =
          declaredMember is Field ||
          declaredMember is Procedure && declaredMember.isGetter;
      bool interfaceMemberHasGetter =
          interfaceMember is Field ||
          interfaceMember is Procedure && interfaceMember.isGetter;
      bool declaredMemberHasSetter =
          (declaredMember is Field &&
              !declaredMember.isFinal &&
              !declaredMember.isConst) ||
          declaredMember is Procedure && declaredMember.isSetter;
      bool interfaceMemberHasSetter =
          (interfaceMember is Field &&
              !(interfaceMember.isFinal && !interfaceMember.isLate) &&
              !interfaceMember.isConst) ||
          interfaceMember is Procedure && interfaceMember.isSetter;
      if (declaredMemberHasGetter && interfaceMemberHasGetter) {
        checkGetterOverride(
          types,
          declaredMember,
          interfaceMember,
          interfaceMemberOrigin,
          isInterfaceCheck,
          localMember: localMember,
        );
      }
      if (declaredMemberHasSetter && interfaceMemberHasSetter) {
        bool seenCovariant = checkSetterOverride(
          types,
          declaredMember,
          interfaceMember,
          interfaceMemberOrigin,
          isInterfaceCheck,
          localMember: localMember,
        );
        if (seenCovariant) {
          _handleSeenCovariant(
            memberHierarchy,
            interfaceMember,
            isSetter,
            callback,
          );
        }
      }
    }
    // TODO(ahe): Handle other cases: accessors, operators, and fields.
  }

  Uri _getMemberUri(Member member) {
    if (member is Field) return member.fileUri;
    if (member is Procedure) return member.fileUri;
    // Other member types won't be seen because constructors don't participate
    // in override relationships
    return unhandled('${member.runtimeType}', '_getMemberUri', -1, null);
  }

  Substitution? _computeInterfaceSubstitution(
    Types types,
    Member declaredMember,
    Member interfaceMember,
    Member interfaceMemberOrigin,
    FunctionNode? declaredFunction,
    FunctionNode? interfaceFunction,
    bool isInterfaceCheck, {
    required Member? localMember,
    required Substitution? declaredSubstitution,
  }) {
    Substitution? interfaceSubstitution;
    if (interfaceMember.enclosingClass!.typeParameters.isNotEmpty) {
      Class enclosingClass = interfaceMember.enclosingClass!;
      interfaceSubstitution = Substitution.fromPairs(
        enclosingClass.typeParameters,
        types.hierarchy.getInterfaceTypeArgumentsAsInstanceOfClass(
          thisType,
          enclosingClass,
        )!,
      );
    }

    if (declaredFunction?.typeParameters.length !=
        interfaceFunction?.typeParameters.length) {
      reportInvalidOverride(
        isInterfaceCheck,
        declaredMember,
        diag.overrideTypeParametersMismatch.withArguments(
          declaredMemberName:
              "${declaredMember.enclosingClass!.name}."
              "${declaredMember.name.text}",
          overriddenMemberName:
              "${interfaceMemberOrigin.enclosingClass!.name}."
              "${interfaceMemberOrigin.name.text}",
        ),
        declaredMember.fileOffset,
        noLength,
        context: [
          diag.overriddenMethodCause
              .withArguments(methodName: interfaceMemberOrigin.name.text)
              .withLocation(
                _getMemberUri(interfaceMemberOrigin),
                interfaceMemberOrigin.fileOffset,
                noLength,
              ),
        ],
        localMember: localMember,
      );
    } else if (declaredFunction?.typeParameters != null) {
      // Since the bound of `interfaceFunction!.parameter[i]` may have changed
      // during substitution, it can affect the nullabilities of the types in
      // the substitution map. The first parameter to
      // [TypeParameterType.forAlphaRenaming] should be updated to account for
      // the change.
      List<TypeParameter> interfaceTypeParameters;
      if (interfaceSubstitution == null) {
        interfaceTypeParameters = interfaceFunction!.typeParameters;
      } else {
        FreshTypeParameters freshTypeParameters = getFreshTypeParameters(
          interfaceFunction!.typeParameters,
        );
        interfaceTypeParameters = freshTypeParameters.freshTypeParameters;
        for (TypeParameter parameter in interfaceTypeParameters) {
          parameter.bound = interfaceSubstitution.substituteType(
            parameter.bound,
          );
        }
        updateBoundNullabilities(interfaceTypeParameters);
      }

      Substitution substitution;
      if (declaredFunction!.typeParameters.isEmpty) {
        substitution = Substitution.empty;
      } else if (declaredFunction.typeParameters.length == 1) {
        substitution = Substitution.fromSingleton(
          interfaceFunction.typeParameters[0],
          new TypeParameterType.withDefaultNullability(
            declaredFunction.typeParameters[0],
          ),
        );
      } else {
        Map<TypeParameter, DartType> substitutionMap =
            <TypeParameter, DartType>{};
        for (int i = 0; i < declaredFunction.typeParameters.length; ++i) {
          substitutionMap[interfaceFunction.typeParameters[i]] =
              new TypeParameterType.withDefaultNullability(
                declaredFunction.typeParameters[i],
              );
        }
        substitution = Substitution.fromMap(substitutionMap);
      }
      for (int i = 0; i < declaredFunction.typeParameters.length; ++i) {
        TypeParameter declaredParameter = declaredFunction.typeParameters[i];
        TypeParameter interfaceParameter = interfaceFunction.typeParameters[i];
        if (!interfaceParameter.isCovariantByClass) {
          DartType declaredBound = declaredParameter.bound;
          DartType interfaceBound = interfaceParameter.bound;
          if (declaredSubstitution != null) {
            declaredBound = declaredSubstitution.substituteType(declaredBound);
          }
          if (interfaceSubstitution != null) {
            interfaceBound = interfaceSubstitution.substituteType(
              interfaceBound,
            );
          }
          DartType computedBound = substitution.substituteType(interfaceBound);
          if (!types
              .performMutualSubtypesCheck(declaredBound, computedBound)
              .isSuccess()) {
            reportInvalidOverride(
              isInterfaceCheck,
              declaredMember,
              diag.overrideTypeParametersBoundMismatch.withArguments(
                declaredBoundType: declaredBound,
                typeVariableName: declaredParameter.name!,
                declaredMemberName:
                    "${declaredMember.enclosingClass!.name}."
                    "${declaredMember.name.text}",
                overriddenBoundType: computedBound,
                overriddenMemberName:
                    "${interfaceMemberOrigin.enclosingClass!.name}."
                    "${interfaceMemberOrigin.name.text}",
              ),
              declaredMember.fileOffset,
              noLength,
              context: [
                diag.overriddenMethodCause
                    .withArguments(methodName: interfaceMemberOrigin.name.text)
                    .withLocation(
                      _getMemberUri(interfaceMemberOrigin),
                      interfaceMemberOrigin.fileOffset,
                      noLength,
                    ),
              ],
              localMember: localMember,
            );
          }
        }
      }
      if (interfaceSubstitution != null) {
        interfaceSubstitution = Substitution.combine(
          interfaceSubstitution,
          substitution,
        );
      } else {
        interfaceSubstitution = substitution;
      }
    }
    return interfaceSubstitution;
  }

  Substitution? _computeDeclaredSubstitution(
    Types types,
    Member declaredMember,
  ) {
    Substitution? declaredSubstitution;
    if (declaredMember.enclosingClass!.typeParameters.isNotEmpty) {
      Class enclosingClass = declaredMember.enclosingClass!;
      declaredSubstitution = Substitution.fromPairs(
        enclosingClass.typeParameters,
        types.hierarchy.getInterfaceTypeArgumentsAsInstanceOfClass(
          thisType,
          enclosingClass,
        )!,
      );
    }
    return declaredSubstitution;
  }

  void _checkTypes(
    Types types,
    Substitution? interfaceSubstitution,
    Substitution? declaredSubstitution,
    Member declaredMember,
    Member interfaceMember,
    Member interfaceMemberOrigin,
    DartType declaredType,
    DartType interfaceType,
    bool isCovariantByDeclaration,
    VariableDeclaration? declaredParameter,
    bool isInterfaceCheck, {
    bool asIfDeclaredParameter = false,
    required Member? localMember,
  }) {
    if (interfaceSubstitution != null) {
      interfaceType = interfaceSubstitution.substituteType(interfaceType);
    }
    if (declaredSubstitution != null) {
      declaredType = declaredSubstitution.substituteType(declaredType);
    }

    bool inParameter = declaredParameter != null || asIfDeclaredParameter;
    DartType subtype = inParameter ? interfaceType : declaredType;
    DartType supertype = inParameter ? declaredType : interfaceType;

    if (types.isSubtypeOf(subtype, supertype)) {
      // No problem--the proper subtyping relation is satisfied.
    } else if (isCovariantByDeclaration &&
        types.isSubtypeOf(supertype, subtype)) {
      // No problem--the overriding parameter is marked "covariant" and has
      // a type which is a subtype of the parameter it overrides.
    } else if (subtype is InvalidType || supertype is InvalidType) {
      // Don't report a problem as something else is wrong that has already
      // been reported.
    } else {
      // Report an error.
      String declaredMemberName =
          '${declaredMember.enclosingClass!.name}'
          '.${declaredMember.name.text}';
      String interfaceMemberName =
          '${interfaceMemberOrigin.enclosingClass!.name}'
          '.${interfaceMemberOrigin.name.text}';
      Message message;
      int fileOffset;
      if (declaredParameter == null) {
        if (asIfDeclaredParameter) {
          // Setter overridden by field
          message = diag.overrideTypeMismatchSetter.withArguments(
            declaredMemberName: declaredMemberName,
            declaredType: declaredType,
            overriddenType: interfaceType,
            overriddenMemberName: interfaceMemberName,
          );
        } else {
          message = diag.overrideTypeMismatchReturnType.withArguments(
            declaredMemberName: declaredMemberName,
            declaredType: declaredType,
            overriddenType: interfaceType,
            overriddenMemberName: interfaceMemberName,
          );
        }
        fileOffset = declaredMember.fileOffset;
      } else {
        message = diag.overrideTypeMismatchParameter.withArguments(
          parameterName: declaredParameter.name!,
          declaredMemberName: declaredMemberName,
          declaredType: declaredType,
          overriddenType: interfaceType,
          overriddenMemberName: interfaceMemberName,
        );
        fileOffset = declaredParameter.fileOffset;
      }
      reportInvalidOverride(
        isInterfaceCheck,
        declaredMember,
        message,
        fileOffset,
        noLength,
        context: [
          diag.overriddenMethodCause
              .withArguments(methodName: interfaceMemberOrigin.name.text)
              .withLocation(
                _getMemberUri(interfaceMemberOrigin),
                interfaceMemberOrigin.fileOffset,
                noLength,
              ),
        ],
        localMember: localMember,
      );
    }
  }

  /// Checks whether [declaredMember] correctly overrides [interfaceMember].
  ///
  /// If an error is reporter [interfaceMemberOrigin] is used as the context
  /// for where [interfaceMember] was declared, since [interfaceMember] might
  /// itself be synthesized.
  ///
  /// Returns whether a covariant parameter was seen and more methods thus have
  /// to be checked.
  bool checkMethodOverride(
    Types types,
    Procedure declaredMember,
    Procedure interfaceMember,
    Member interfaceMemberOrigin,
    bool isInterfaceCheck, {
    required Member? localMember,
  }) {
    assert(declaredMember.kind == interfaceMember.kind);
    assert(
      declaredMember.kind == ProcedureKind.Method ||
          declaredMember.kind == ProcedureKind.Operator,
    );
    bool seenCovariant = false;
    FunctionNode declaredFunction = declaredMember.function;
    FunctionType? declaredSignatureType = declaredMember.signatureType;
    FunctionNode interfaceFunction = interfaceMember.function;
    FunctionType? interfaceSignatureType = interfaceMember.signatureType;

    Substitution? declaredSubstitution = _computeDeclaredSubstitution(
      types,
      declaredMember,
    );

    Substitution? interfaceSubstitution = _computeInterfaceSubstitution(
      types,
      declaredMember,
      interfaceMember,
      interfaceMemberOrigin,
      declaredFunction,
      interfaceFunction,
      isInterfaceCheck,
      localMember: localMember,
      declaredSubstitution: declaredSubstitution,
    );

    _checkTypes(
      types,
      interfaceSubstitution,
      declaredSubstitution,
      declaredMember,
      interfaceMember,
      interfaceMemberOrigin,
      declaredFunction.returnType,
      interfaceFunction.returnType,
      /* isCovariantByDeclaration = */ false,
      /* declaredParameter = */ null,
      isInterfaceCheck,
      localMember: localMember,
    );
    if (declaredFunction.positionalParameters.length <
        interfaceFunction.positionalParameters.length) {
      reportInvalidOverride(
        isInterfaceCheck,
        declaredMember,
        diag.overrideFewerPositionalArguments.withArguments(
          declaredMemberName:
              "${declaredMember.enclosingClass!.name}."
              "${declaredMember.name.text}",
          overriddenMemberName:
              "${interfaceMemberOrigin.enclosingClass!.name}."
              "${interfaceMemberOrigin.name.text}",
        ),
        declaredMember.fileOffset,
        noLength,
        context: [
          diag.overriddenMethodCause
              .withArguments(methodName: interfaceMemberOrigin.name.text)
              .withLocation(
                interfaceMemberOrigin.fileUri,
                interfaceMemberOrigin.fileOffset,
                noLength,
              ),
        ],
        localMember: localMember,
      );
    }
    if (interfaceFunction.requiredParameterCount <
        declaredFunction.requiredParameterCount) {
      reportInvalidOverride(
        isInterfaceCheck,
        declaredMember,
        diag.overrideMoreRequiredArguments.withArguments(
          declaredMemberName:
              "${declaredMember.enclosingClass!.name}."
              "${declaredMember.name.text}",
          overriddenMemberName:
              "${interfaceMemberOrigin.enclosingClass!.name}."
              "${interfaceMemberOrigin.name.text}",
        ),
        declaredMember.fileOffset,
        noLength,
        context: [
          diag.overriddenMethodCause
              .withArguments(methodName: interfaceMemberOrigin.name.text)
              .withLocation(
                interfaceMemberOrigin.fileUri,
                interfaceMemberOrigin.fileOffset,
                noLength,
              ),
        ],
        localMember: localMember,
      );
    }
    for (
      int i = 0;
      i < declaredFunction.positionalParameters.length &&
          i < interfaceFunction.positionalParameters.length;
      i++
    ) {
      VariableDeclaration declaredParameter =
          declaredFunction.positionalParameters[i];
      VariableDeclaration interfaceParameter =
          interfaceFunction.positionalParameters[i];
      DartType declaredParameterType = declaredParameter.type;
      if (declaredSignatureType != null) {
        declaredParameterType = declaredSignatureType.positionalParameters[i];
      }
      DartType interfaceParameterType = interfaceParameter.type;
      if (interfaceSignatureType != null) {
        interfaceParameterType = interfaceSignatureType.positionalParameters[i];
      }
      if (i == 0 &&
          declaredMember.name == equalsName &&
          declaredParameterType ==
              types.hierarchy.coreTypes.objectNonNullableRawType &&
          interfaceParameter.type is DynamicType) {
        // TODO(johnniwinther): Add check for opt-in overrides of operator ==.
        // `operator ==` methods in opt-out classes have type
        // `bool Function(dynamic)`.
        continue;
      }

      _checkTypes(
        types,
        interfaceSubstitution,
        declaredSubstitution,
        declaredMember,
        interfaceMember,
        interfaceMemberOrigin,
        declaredParameterType,
        interfaceParameterType,
        declaredParameter.isCovariantByDeclaration ||
            interfaceParameter.isCovariantByDeclaration,
        declaredParameter,
        isInterfaceCheck,
        localMember: localMember,
      );
      if (declaredParameter.isCovariantByDeclaration) seenCovariant = true;
    }
    if (declaredFunction.namedParameters.isEmpty &&
        interfaceFunction.namedParameters.isEmpty) {
      return seenCovariant;
    }
    if (declaredFunction.namedParameters.length <
        interfaceFunction.namedParameters.length) {
      reportInvalidOverride(
        isInterfaceCheck,
        declaredMember,
        diag.overrideFewerNamedArguments.withArguments(
          declaredMemberName:
              "${declaredMember.enclosingClass!.name}."
              "${declaredMember.name.text}",
          overriddenMemberName:
              "${interfaceMemberOrigin.enclosingClass!.name}."
              "${interfaceMemberOrigin.name.text}",
        ),
        declaredMember.fileOffset,
        noLength,
        context: [
          diag.overriddenMethodCause
              .withArguments(methodName: interfaceMemberOrigin.name.text)
              .withLocation(
                interfaceMemberOrigin.fileUri,
                interfaceMemberOrigin.fileOffset,
                noLength,
              ),
        ],
        localMember: localMember,
      );
    }

    int compareNamedParameters(VariableDeclaration p0, VariableDeclaration p1) {
      return p0.name!.compareTo(p1.name!);
    }

    List<VariableDeclaration> sortedFromDeclared = new List.of(
      declaredFunction.namedParameters,
    )..sort(compareNamedParameters);
    List<VariableDeclaration> sortedFromInterface = new List.of(
      interfaceFunction.namedParameters,
    )..sort(compareNamedParameters);
    Iterator<VariableDeclaration> declaredNamedParameters =
        sortedFromDeclared.iterator;
    Iterator<VariableDeclaration> interfaceNamedParameters =
        sortedFromInterface.iterator;
    outer:
    while (declaredNamedParameters.moveNext() &&
        interfaceNamedParameters.moveNext()) {
      while (declaredNamedParameters.current.name !=
          interfaceNamedParameters.current.name) {
        if (!declaredNamedParameters.moveNext()) {
          reportInvalidOverride(
            isInterfaceCheck,
            declaredMember,
            diag.overrideMismatchNamedParameter.withArguments(
              declaredMemberName:
                  "${declaredMember.enclosingClass!.name}."
                  "${declaredMember.name.text}",
              parameterName: interfaceNamedParameters.current.name!,
              overriddenMemberName:
                  "${interfaceMember.enclosingClass!.name}."
                  "${interfaceMember.name.text}",
            ),
            declaredMember.fileOffset,
            noLength,
            context: [
              diag.overriddenMethodCause
                  .withArguments(methodName: interfaceMember.name.text)
                  .withLocation(
                    interfaceMember.fileUri,
                    interfaceMember.fileOffset,
                    noLength,
                  ),
            ],
            localMember: localMember,
          );
          break outer;
        }
      }
      VariableDeclaration declaredParameter = declaredNamedParameters.current;
      _checkTypes(
        types,
        interfaceSubstitution,
        declaredSubstitution,
        declaredMember,
        interfaceMember,
        interfaceMemberOrigin,
        declaredParameter.type,
        interfaceNamedParameters.current.type,
        declaredParameter.isCovariantByDeclaration,
        declaredParameter,
        isInterfaceCheck,
        localMember: localMember,
      );
      if (declaredParameter.isRequired &&
          !interfaceNamedParameters.current.isRequired) {
        reportInvalidOverride(
          isInterfaceCheck,
          declaredMember,
          diag.overrideMismatchRequiredNamedParameter.withArguments(
            parameterName: declaredParameter.name!,
            declaredMemberName:
                "${declaredMember.enclosingClass!.name}."
                "${declaredMember.name.text}",
            overriddenMemberName:
                "${interfaceMember.enclosingClass!.name}."
                "${interfaceMember.name.text}",
          ),
          declaredParameter.fileOffset,
          noLength,
          context: [
            diag.overriddenMethodCause
                .withArguments(methodName: interfaceMemberOrigin.name.text)
                .withLocation(
                  _getMemberUri(interfaceMemberOrigin),
                  interfaceMemberOrigin.fileOffset,
                  noLength,
                ),
          ],
          localMember: localMember,
        );
      }
      if (declaredParameter.isCovariantByDeclaration) seenCovariant = true;
    }
    return seenCovariant;
  }

  /// Checks whether [declaredMember] correctly overrides [interfaceMember].
  ///
  /// If an error is reporter [interfaceMemberOrigin] is used as the context
  /// for where [interfaceMember] was declared, since [interfaceMember] might
  /// itself be synthesized.
  void checkGetterOverride(
    Types types,
    Member declaredMember,
    Member interfaceMember,
    Member interfaceMemberOrigin,
    bool isInterfaceCheck, {
    required Member? localMember,
  }) {
    Substitution? declaredSubstitution = _computeDeclaredSubstitution(
      types,
      declaredMember,
    );
    Substitution? interfaceSubstitution = _computeInterfaceSubstitution(
      types,
      declaredMember,
      interfaceMember,
      interfaceMemberOrigin,
      /* declaredFunction = */
      null,
      /* interfaceFunction = */
      null,
      isInterfaceCheck,
      localMember: localMember,
      declaredSubstitution: declaredSubstitution,
    );
    DartType declaredType = declaredMember.getterType;
    DartType interfaceType = interfaceMember.getterType;
    _checkTypes(
      types,
      interfaceSubstitution,
      declaredSubstitution,
      declaredMember,
      interfaceMember,
      interfaceMemberOrigin,
      declaredType,
      interfaceType,
      /* isCovariantByDeclaration = */
      false,
      /* declaredParameter = */
      null,
      isInterfaceCheck,
      localMember: localMember,
    );
  }

  /// Checks whether [declaredMember] correctly overrides [interfaceMember].
  ///
  /// If an error is reporter [interfaceMemberOrigin] is used as the context
  /// for where [interfaceMember] was declared, since [interfaceMember] might
  /// itself be synthesized.
  ///
  /// Returns whether a covariant parameter was seen and more methods thus have
  /// to be checked.
  bool checkSetterOverride(
    Types types,
    Member declaredMember,
    Member interfaceMember,
    Member interfaceMemberOrigin,
    bool isInterfaceCheck, {
    required Member? localMember,
  }) {
    Substitution? declaredSubstitution = _computeDeclaredSubstitution(
      types,
      declaredMember,
    );
    Substitution? interfaceSubstitution = _computeInterfaceSubstitution(
      types,
      declaredMember,
      interfaceMember,
      interfaceMemberOrigin,
      /* declaredFunction = */
      null,
      /* interfaceFunction = */
      null,
      isInterfaceCheck,
      localMember: localMember,
      declaredSubstitution: declaredSubstitution,
    );
    DartType declaredType = declaredMember.setterType;
    DartType interfaceType = interfaceMember.setterType;
    VariableDeclaration? declaredParameter = declaredMember
        .function
        ?.positionalParameters
        .elementAt(0);
    bool isCovariantByDeclaration =
        declaredParameter?.isCovariantByDeclaration ?? false;
    if (!isCovariantByDeclaration && declaredMember is Field) {
      isCovariantByDeclaration = declaredMember.isCovariantByDeclaration;
    }
    if (!isCovariantByDeclaration && interfaceMember is Field) {
      isCovariantByDeclaration = interfaceMember.isCovariantByDeclaration;
    }
    _checkTypes(
      types,
      interfaceSubstitution,
      declaredSubstitution,
      declaredMember,
      interfaceMember,
      interfaceMemberOrigin,
      declaredType,
      interfaceType,
      isCovariantByDeclaration,
      declaredParameter,
      isInterfaceCheck,
      asIfDeclaredParameter: true,
      localMember: localMember,
    );
    return isCovariantByDeclaration;
  }

  // When the overriding member is inherited, report the class containing
  // the conflict as the main error.
  void reportInvalidOverride(
    bool isInterfaceCheck,
    Member declaredMember,
    Message message,
    int fileOffset,
    int length, {
    List<LocatedMessage>? context,
    required Member? localMember,
  }) {
    if (shouldOverrideProblemBeOverlooked(this)) {
      return;
    }

    switch (localMember) {
      case Procedure():
        localMember.isErroneous = true;
      case Field():
        localMember.isErroneous = true;
      case Constructor():
        // Coverage-ignore(suite): Not run.
        unexpected("Procedure|Field", "Constructor", fileOffset, fileUri);
      case null:
      // Do nothing.
    }

    if (declaredMember.enclosingClass == cls) {
      // Ordinary override
      libraryBuilder.addProblem(
        message,
        fileOffset,
        length,
        declaredMember.fileUri,
        context: context,
      );
    } else {
      context = [
        message.withLocation(declaredMember.fileUri, fileOffset, length),
        ...?context,
      ];
      if (isInterfaceCheck) {
        // Interface check
        libraryBuilder.addProblem(
          diag.interfaceCheck.withArguments(
            memberName: declaredMember.name.text,
            className: cls.name,
          ),
          cls.fileOffset,
          cls.name.length,
          cls.fileUri,
          context: context,
        );
      } else {
        if (cls.isAnonymousMixin) {
          // Implicit mixin application class
          String baseName = cls.superclass!.demangledName;
          String mixinName = cls.mixedInClass!.name;
          int classNameLength = cls.nameAsMixinApplicationSubclass.length;
          libraryBuilder.addProblem(
            diag.implicitMixinOverride.withArguments(
              mixinName: mixinName,
              baseName: baseName,
              erroneousMember: declaredMember.name.text,
            ),
            cls.fileOffset,
            classNameLength,
            cls.fileUri,
            context: context,
          );
        } else {
          // Named mixin application class
          libraryBuilder.addProblem(
            diag.namedMixinOverride.withArguments(
              className: cls.name,
              overriddenMemberName: declaredMember.name.text,
            ),
            cls.fileOffset,
            cls.name.length,
            cls.fileUri,
            context: context,
          );
        }
      }
    }
  }

  // Coverage-ignore(suite): Not run.
  /// Returns an iterator the origin class and all augmentations in application
  /// order.
  Iterator<SourceClassBuilder> get declarationIterator =>
      new AugmentationIterator<SourceClassBuilder>(this, null);

  @override
  // Coverage-ignore(suite): Not run.
  Reference get reference => cls.reference;
}

/// Returns `true` if override problems should be overlooked.
///
/// This is needed for the current encoding of some JavaScript implementation
/// classes that are not valid Dart. For instance `JSInt` in
/// 'dart:_interceptors' that implements both `int` and `double`, and `JsArray`
/// in `dart:js` that implement both `ListMixin` and `JsObject`.
bool shouldOverrideProblemBeOverlooked(ClassBuilder classBuilder) {
  return getOverlookedOverrideProblemChoice(classBuilder) != null;
}

/// Returns the index of the member to use if an override problems should be
/// overlooked.
///
/// This is needed for the current encoding of some JavaScript implementation
/// classes that are not valid Dart. For instance `JSInt` in
/// 'dart:_interceptors' that implements both `int` and `double`, and `JsArray`
/// in `dart:js` that implement both `ListMixin` and `JsObject`.
int? getOverlookedOverrideProblemChoice(DeclarationBuilder declarationBuilder) {
  String uri = '${declarationBuilder.libraryBuilder.importUri}';
  if (uri == 'dart:js' &&
      // Coverage-ignore(suite): Not run.
      declarationBuilder.fileUri.pathSegments.last == 'js.dart') {
    return 0;
  } else if (uri == 'dart:_interceptors' &&
      // Coverage-ignore(suite): Not run.
      declarationBuilder.fileUri.pathSegments.last == 'js_number.dart') {
    return 1;
  }
  return null;
}

TypeBuilder? _applyMixins({
  required ProblemReporting problemReporting,
  required SourceLibraryBuilder enclosingLibraryBuilder,
  required TypeParameterFactory typeParameterFactory,
  required TypeBuilder? supertype,
  required List<TypeBuilder>? mixins,
  required int startOffset,
  required int nameOffset,
  required int endOffset,
  required String subclassName,
  required bool isMixinDeclaration,
  required IndexedLibrary? indexedLibrary,
  required ExtensionScope extensionScope,
  required LookupScope compilationUnitScope,
  required Map<SourceClassBuilder, TypeBuilder> mixinApplications,
  required Uri fileUri,
  List<SourceNominalParameterBuilder>? typeParameters,
  required Modifiers modifiers,
  required TypeBuilder objectTypeBuilder,
  required void Function(SourceClassBuilder) onAnonymousMixin,
}) {
  if (mixins == null) {
    return supertype;
  }
  // Documentation below assumes the given mixin application is in one of
  // these forms:
  //
  //     class C extends S with M1, M2, M3;
  //     class Named = S with M1, M2, M3;
  //
  // When we refer to the subclass, we mean `C` or `Named`.

  /// The current supertype.
  ///
  /// Starts out having the value `S` and on each iteration of the loop
  /// below, it will take on the value corresponding to:
  ///
  /// 1. `S with M1`.
  /// 2. `(S with M1) with M2`.
  /// 3. `((S with M1) with M2) with M3`.
  supertype ??= objectTypeBuilder;

  /// The variable part of the mixin application's synthetic name. It
  /// starts out as the name of the superclass, but is only used after it
  /// has been combined with the name of the current mixin. In the examples
  /// from above, it will take these values:
  ///
  /// 1. `S&M1`
  /// 2. `S&M1&M2`
  /// 3. `S&M1&M2&M3`.
  ///
  /// The full name of the mixin application is obtained by prepending the
  /// name of the subclass (`C` or `Named` in the above examples) to the
  /// running name. For the example `C`, that leads to these full names:
  ///
  /// 1. `_C&S&M1`
  /// 2. `_C&S&M1&M2`
  /// 3. `_C&S&M1&M2&M3`.
  ///
  /// For a named mixin application, the last name has been given by the
  /// programmer, so for the example `Named` we see these full names:
  ///
  /// 1. `_Named&S&M1`
  /// 2. `_Named&S&M1&M2`
  /// 3. `Named`.
  String runningName;
  if (supertype.typeName == null) {
    assert(supertype is FunctionTypeBuilder);

    // Function types don't have names, and we can supply any string that
    // doesn't have to be unique. The actual supertype of the mixin will
    // not be built in that case.
    runningName = "";
  } else {
    runningName = supertype.typeName!.name;
  }

  /// The names of the type parameters of the subclass.
  Set<String>? typeParameterNames;
  if (typeParameters != null) {
    typeParameterNames = new Set<String>();
    for (NominalParameterBuilder typeParameter in typeParameters) {
      typeParameterNames.add(typeParameter.name);
    }
  }

  /// Iterate over the mixins from left to right. At the end of each
  /// iteration, a new [supertype] is computed that is the mixin
  /// application of [supertype] with the current mixin.
  for (int i = 0; i < mixins.length; i++) {
    TypeBuilder mixin = mixins[i];
    bool isGeneric = false;
    if (typeParameterNames != null) {
      if (supertype != null) {
        isGeneric =
            isGeneric || supertype.usesTypeParameters(typeParameterNames);
      }
      isGeneric = isGeneric || mixin.usesTypeParameters(typeParameterNames);
    }
    TypeName? typeName = mixin.typeName;
    if (typeName != null) {
      runningName += "&${typeName.name}";
    }
    String fullname = "_$subclassName&$runningName";
    List<SourceNominalParameterBuilder>? applicationTypeParameters;
    List<TypeBuilder>? applicationTypeArguments;
    ClassDeclaration classDeclaration;
    final int computedStartOffset;
    // Otherwise, we pass the fresh type parameters to the mixin
    // application in the same order as they're declared on the subclass.
    if (isGeneric) {
      NominalParameterNameSpace nominalParameterNameSpace =
          new NominalParameterNameSpace();

      NominalParameterCopy nominalVariableCopy = typeParameterFactory
          .copyTypeParameters(
            oldParameterBuilders: typeParameters,
            kind: TypeParameterKind.extensionSynthesized,
            instanceTypeParameterAccess:
                InstanceTypeParameterAccessState.Allowed,
          )!;

      applicationTypeParameters = nominalVariableCopy.newParameterBuilders;
      Map<NominalParameterBuilder, NominalParameterBuilder>
      newToOldVariableMap = nominalVariableCopy.newToOldParameterMap;

      Map<NominalParameterBuilder, TypeBuilder> substitutionMap =
          nominalVariableCopy.substitutionMap;

      applicationTypeArguments = [];
      for (NominalParameterBuilder typeParameter in typeParameters!) {
        TypeBuilder applicationTypeArgument =
            new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
              // The type parameter types passed as arguments to the
              // generic class representing the anonymous mixin
              // application should refer back to the type parameters of
              // the class that extend the anonymous mixin application.
              typeParameter,
              const NullabilityBuilder.omitted(),
              fileUri: fileUri,
              charOffset: nameOffset,
              instanceTypeParameterAccess:
                  InstanceTypeParameterAccessState.Allowed,
            );
        applicationTypeArguments.add(applicationTypeArgument);
      }
      nominalParameterNameSpace.addTypeParameters(
        problemReporting,
        applicationTypeParameters,
        ownerName: fullname,
        allowNameConflict: true,
      );
      if (supertype != null) {
        supertype = new SynthesizedTypeBuilder(
          supertype,
          newToOldVariableMap,
          substitutionMap,
        );
      }
      mixin = new SynthesizedTypeBuilder(
        mixin,
        newToOldVariableMap,
        substitutionMap,
      );
    }
    computedStartOffset = startOffset;
    classDeclaration = new AnonymousMixinApplication(
      name: fullname,
      extensionScope: extensionScope,
      compilationUnitScope: compilationUnitScope,
      supertype: isMixinDeclaration ? null : supertype,
      interfaces: isMixinDeclaration ? [supertype!, mixin] : null,
      fileUri: fileUri,
      startOffset: computedStartOffset,
      nameOffset: nameOffset,
      endOffset: endOffset,
    );

    IndexedClass? indexedClass;
    if (indexedLibrary != null) {
      indexedClass = indexedLibrary.lookupIndexedClass(fullname);
    }

    LookupScope typeParameterScope = TypeParameterScope.fromList(
      compilationUnitScope,
      typeParameters,
    );
    DeclarationNameSpaceBuilder nameSpaceBuilder =
        new DeclarationNameSpaceBuilder.empty();
    SourceClassBuilder application = new SourceClassBuilder(
      modifiers: Modifiers.Abstract,
      name: fullname,
      typeParameters: applicationTypeParameters,
      typeParameterScope: typeParameterScope,
      nameSpaceBuilder: nameSpaceBuilder,
      libraryBuilder: enclosingLibraryBuilder,
      fileUri: fileUri,
      nameOffset: nameOffset,
      indexedClass: indexedClass,
      mixedInTypeBuilder: isMixinDeclaration ? null : mixin,
      introductory: classDeclaration,
    );
    // TODO(ahe, kmillikin): Should always be true?
    // pkg/analyzer/test/src/summary/resynthesize_kernel_test.dart can't
    // handle that :(
    application.cls.isAnonymousMixin = true;
    onAnonymousMixin(application);
    supertype = new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
      application,
      const NullabilityBuilder.omitted(),
      arguments: applicationTypeArguments,
      fileUri: fileUri,
      charOffset: nameOffset,
      instanceTypeParameterAccess: InstanceTypeParameterAccessState.Allowed,
    );
    mixinApplications[application] = mixin;
  }
  return supertype;
}
