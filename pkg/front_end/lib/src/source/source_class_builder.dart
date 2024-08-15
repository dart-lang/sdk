// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_class_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClassHierarchyBase, ClassHierarchyMembers;
import 'package:kernel/core_types.dart';
import 'package:kernel/names.dart' show equalsName;
import 'package:kernel/reference_from_index.dart' show IndexedClass;
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

import '../base/name_space.dart';
import '../base/problems.dart' show unexpected, unhandled, unimplemented;
import '../base/scope.dart';
import '../builder/augmentation_iterator.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/named_type_builder.dart';
import '../builder/never_type_declaration_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/type_builder.dart';
import '../builder/void_type_declaration_builder.dart';
import '../codes/cfe_codes.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/hierarchy/hierarchy_builder.dart';
import '../kernel/hierarchy/hierarchy_node.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/type_algorithms.dart' show computeTypeVariableBuilderVariance;
import '../kernel/utils.dart' show compareProcedures;
import 'class_declaration.dart';
import 'source_builder_mixins.dart';
import 'source_constructor_builder.dart';
import 'source_factory_builder.dart';
import 'source_field_builder.dart';
import 'source_library_builder.dart';
import 'source_loader.dart';
import 'source_member_builder.dart';
import 'type_parameter_scope_builder.dart';

Class initializeClass(
    List<NominalVariableBuilder>? typeVariables,
    String name,
    SourceLibraryBuilder parent,
    int startCharOffset,
    int charOffset,
    int charEndOffset,
    IndexedClass? indexedClass,
    {required bool isAugmentation}) {
  Class cls = new Class(
      name: name,
      typeParameters:
          NominalVariableBuilder.typeParametersFromBuilders(typeVariables),
      // If the class is an augmentation class it shouldn't use the reference
      // from index even when available.
      // TODO(johnniwinther): Avoid creating [Class] so early in the builder
      // that we end up creating unneeded nodes.
      reference: isAugmentation ? null : indexedClass?.reference,
      fileUri: parent.fileUri);
  if (cls.startFileOffset == TreeNode.noOffset) {
    cls.startFileOffset = startCharOffset;
  }
  if (cls.fileOffset == TreeNode.noOffset) {
    cls.fileOffset = charOffset;
  }
  if (cls.fileEndOffset == TreeNode.noOffset) {
    cls.fileEndOffset = charEndOffset;
  }

  return cls;
}

class SourceClassBuilder extends ClassBuilderImpl
    with ClassDeclarationMixin, SourceTypedDeclarationBuilderMixin
    implements
        Comparable<SourceClassBuilder>,
        ClassDeclaration,
        SourceDeclarationBuilder {
  final Class actualCls;

  final DeclarationNameSpaceBuilder nameSpaceBuilder;

  late final LookupScope _scope;

  late final DeclarationNameSpace _nameSpace;

  late final ConstructorScope _constructorScope;

  @override
  List<NominalVariableBuilder>? typeVariables;

  /// The scope in which the [typeParameters] are declared.
  final LookupScope typeParameterScope;

  @override
  TypeBuilder? supertypeBuilder;

  @override
  List<TypeBuilder>? interfaceBuilders;

  @override
  List<TypeBuilder>? onTypes;

  @override
  final List<ConstructorReferenceBuilder>? constructorReferences;

  @override
  TypeBuilder? mixedInTypeBuilder;

  final IndexedClass? indexedClass;

  @override
  final bool isMacro;

  @override
  final bool isSealed;

  @override
  final bool isBase;

  @override
  final bool isInterface;

  @override
  final bool isFinal;

  /// Set to `true` if this class is declared using the `augment` modifier.
  final bool isAugmentation;

  @override
  final bool isMixinClass;

  @override
  bool isMixinDeclaration;

  bool? _isConflictingAugmentationMember;

  /// Returns `true` if this class is a class declared in an augmentation
  /// library that conflicts with a declaration in the origin library.
  bool get isConflictingAugmentationMember {
    return _isConflictingAugmentationMember ??= false;
  }

  void set isConflictingAugmentationMember(bool value) {
    assert(
        _isConflictingAugmentationMember == null,
        // Coverage-ignore(suite): Not run.
        '$this.isConflictingAugmentationMember has already been fixed.');
    _isConflictingAugmentationMember = value;
  }

  List<SourceClassBuilder>? _augmentations;

  MergedClassMemberScope? _mergedScope;

  SourceClassBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      String name,
      this.typeVariables,
      this.supertypeBuilder,
      this.interfaceBuilders,
      this.onTypes,
      this.typeParameterScope,
      this.nameSpaceBuilder,
      SourceLibraryBuilder parent,
      this.constructorReferences,
      int startCharOffset,
      int nameOffset,
      int charEndOffset,
      this.indexedClass,
      {this.mixedInTypeBuilder,
      this.isMixinDeclaration = false,
      this.isMacro = false,
      this.isSealed = false,
      this.isBase = false,
      this.isInterface = false,
      this.isFinal = false,
      bool isAugmentation = false,
      this.isMixinClass = false})
      : actualCls = initializeClass(typeVariables, name, parent,
            startCharOffset, nameOffset, charEndOffset, indexedClass,
            isAugmentation: isAugmentation),
        isAugmentation = isAugmentation,
        super(metadata, modifiers, name, parent, nameOffset) {
    actualCls.hasConstConstructor = declaresConstConstructor;
  }

  @override
  LookupScope get scope => _scope;

  @override
  DeclarationNameSpace get nameSpace => _nameSpace;

  @override
  ConstructorScope get constructorScope => _constructorScope;

  @override
  void buildScopes(LibraryBuilder coreLibrary) {
    _nameSpace = nameSpaceBuilder.buildNameSpace(this);
    _scope = new NameSpaceLookupScope(
        _nameSpace, ScopeKind.declaration, "class $name",
        parent: typeParameterScope);
    _constructorScope =
        new DeclarationNameSpaceConstructorScope(name, _nameSpace);
  }

  MergedClassMemberScope get mergedScope => _mergedScope ??= isAugmenting
      ?
      // Coverage-ignore(suite): Not run.
      origin.mergedScope
      : new MergedClassMemberScope(this);

  // Coverage-ignore(suite): Not run.
  List<SourceClassBuilder>? get augmentationsForTesting => _augmentations;

  SourceClassBuilder? actualOrigin;

  @override
  SourceClassBuilder get origin => actualOrigin ?? this;

  @override
  Class get cls => origin.actualCls;

  @override
  SourceLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as SourceLibraryBuilder;

  Class build(LibraryBuilder coreLibrary) {
    SourceLibraryBuilder.checkMemberConflicts(libraryBuilder, nameSpace,
        // These checks are performed as part of the class hierarchy
        // computation.
        checkForInstanceVsStaticConflict: false,
        checkForMethodVsSetterConflict: false);

    void buildBuilders(Builder declaration) {
      if (declaration.parent != this) {
        if (declaration.parent?.origin != origin) {
          // Coverage-ignore-block(suite): Not run.
          if (fileUri != declaration.parent?.fileUri) {
            unexpected("$fileUri", "${declaration.parent?.fileUri}", charOffset,
                fileUri);
          } else {
            unexpected(
                fullNameForErrors,
                declaration.parent?.fullNameForErrors ?? '',
                charOffset,
                fileUri);
          }
        }
      } else if (declaration is SourceMemberBuilder) {
        SourceMemberBuilder memberBuilder = declaration;
        memberBuilder.buildOutlineNodes((
            {required Member member,
            Member? tearOff,
            required BuiltMemberKind kind}) {
          _addMemberToClass(declaration, member);
          if (tearOff != null) {
            _addMemberToClass(declaration, tearOff);
          }
        });
      } else {
        unhandled("${declaration.runtimeType}", "buildBuilders",
            declaration.charOffset, declaration.fileUri);
      }
    }

    nameSpace.unfilteredIterator.forEach(buildBuilders);
    nameSpace.unfilteredConstructorIterator.forEach(buildBuilders);
    if (supertypeBuilder != null) {
      supertypeBuilder = _checkSupertype(supertypeBuilder!);
    }
    Supertype? supertype = supertypeBuilder?.buildSupertype(libraryBuilder,
        isMixinDeclaration ? TypeUse.mixinOnType : TypeUse.classExtendsType);
    if (supertype != null &&
        LibraryBuilder.isFunction(supertype.classNode, coreLibrary)) {
      supertype = null;
      supertypeBuilder = null;
    }
    if (!isMixinDeclaration &&
        actualCls.supertype != null &&
        // Coverage-ignore(suite): Not run.
        actualCls.superclass!.isMixinDeclaration) {
      // Coverage-ignore-block(suite): Not run.
      // Declared mixins have interfaces that can be implemented, but they
      // cannot be extended.  However, a mixin declaration with a single
      // superclass constraint is encoded with the constraint as the supertype,
      // and that is allowed to be a mixin's interface.
      libraryBuilder.addProblem(
          templateSupertypeIsIllegal.withArguments(actualCls.superclass!.name),
          charOffset,
          noLength,
          fileUri);
      supertype = null;
    }
    if (supertype == null && supertypeBuilder is! NamedTypeBuilder) {
      supertypeBuilder = null;
    }
    actualCls.supertype = supertype;

    if (mixedInTypeBuilder != null) {
      mixedInTypeBuilder = _checkSupertype(mixedInTypeBuilder!);
    }
    Supertype? mixedInType =
        mixedInTypeBuilder?.buildMixedInType(libraryBuilder);
    if (mixedInType != null &&
        LibraryBuilder.isFunction(mixedInType.classNode, coreLibrary)) {
      mixedInType = null;
      mixedInTypeBuilder = null;
      actualCls.isAnonymousMixin = false;
      isMixinDeclaration = false;
    }
    if (mixedInType == null && mixedInTypeBuilder is! NamedTypeBuilder) {
      mixedInTypeBuilder = null;
    }
    actualCls.isMixinDeclaration = isMixinDeclaration;
    actualCls.mixedInType = mixedInType;

    // TODO(ahe): If `cls.supertype` is null, and this isn't Object, report a
    // compile-time error.
    cls.isAbstract = isAbstract;
    if (!cls.isMacro) {
      // TODO(jensj): cls / actualCls is not the same --- so for instance it sets
      // macro on the "parent" class depending on whatever it processes last of
      // "non-parent" classes.
      // This means that when a macro class has an augmentation which is not a
      // macro class the macro class will be marked as no longer a macro class
      // and at least via the incremental compiler subsequent applications of it
      // will fail.
      // Now it's *only* set if it's not already a macro, i.e. once it's a macro
      // it stays a macro which seems reasonable although I don't know what the
      // actual rules are.
      cls.isMacro = isMacro;
    }
    cls.isMixinClass = isMixinClass;
    cls.isSealed = isSealed;
    cls.isBase = isBase;
    cls.isInterface = isInterface;
    cls.isFinal = isFinal;

    if (interfaceBuilders != null) {
      for (int i = 0; i < interfaceBuilders!.length; ++i) {
        interfaceBuilders![i] = _checkSupertype(interfaceBuilders![i]);
        Supertype? supertype = interfaceBuilders![i]
            .buildSupertype(libraryBuilder, TypeUse.classImplementsType);
        if (supertype != null) {
          if (LibraryBuilder.isFunction(supertype.classNode, coreLibrary)) {
            continue;
          }
          // TODO(ahe): Report an error if supertype is null.
          actualCls.implementedTypes.add(supertype);
        }
      }
    }

    checkConstructorStaticConflict();

    cls.procedures.sort(compareProcedures);
    return cls;
  }

  BodyBuilderContext createBodyBuilderContext(
      {required bool inOutlineBuildingPhase,
      required bool inMetadata,
      required bool inConstFields}) {
    return new ClassBodyBuilderContext(this,
        inOutlineBuildingPhase: inOutlineBuildingPhase,
        inMetadata: inMetadata,
        inConstFields: inConstFields);
  }

  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    void build(Builder declaration) {
      SourceMemberBuilder member = declaration as SourceMemberBuilder;
      member.buildOutlineExpressions(
          classHierarchy, delayedDefaultValueCloners);
    }

    MetadataBuilder.buildAnnotations(
        isAugmenting ? origin.cls : cls,
        metadata,
        createBodyBuilderContext(
            inOutlineBuildingPhase: true,
            inMetadata: true,
            inConstFields: false),
        libraryBuilder,
        fileUri,
        libraryBuilder.scope,
        createFileUriExpression: isAugmenting);
    if (typeVariables != null) {
      for (int i = 0; i < typeVariables!.length; i++) {
        typeVariables![i].buildOutlineExpressions(
            libraryBuilder,
            createBodyBuilderContext(
                inOutlineBuildingPhase: true,
                inMetadata: true,
                inConstFields: false),
            classHierarchy,
            typeParameterScope);
      }
    }

    nameSpace
        .filteredConstructorIterator(
            parent: this, includeDuplicates: false, includeAugmentations: true)
        .forEach(build);
    nameSpace
        .filteredIterator(
            parent: this, includeDuplicates: false, includeAugmentations: true)
        .forEach(build);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterator<T> localMemberIterator<T extends Builder>() =>
      new ClassDeclarationMemberIterator<SourceClassBuilder, T>.local(this,
          includeDuplicates: false);

  @override
  // Coverage-ignore(suite): Not run.
  Iterator<T> localConstructorIterator<T extends MemberBuilder>() =>
      new ClassDeclarationConstructorIterator<SourceClassBuilder, T>.local(this,
          includeDuplicates: false);

  @override
  Iterator<T> fullMemberIterator<T extends Builder>() =>
      new ClassDeclarationMemberIterator<SourceClassBuilder, T>.full(
          const _SourceClassBuilderAugmentationAccess(), this,
          includeDuplicates: false);

  @override
  // Coverage-ignore(suite): Not run.
  NameIterator<T> fullMemberNameIterator<T extends Builder>() =>
      new ClassDeclarationMemberNameIterator<SourceClassBuilder, T>(
          const _SourceClassBuilderAugmentationAccess(), this,
          includeDuplicates: false);

  @override
  Iterator<T> fullConstructorIterator<T extends MemberBuilder>() =>
      new ClassDeclarationConstructorIterator<SourceClassBuilder, T>.full(
          const _SourceClassBuilderAugmentationAccess(), this,
          includeDuplicates: false);

  @override
  NameIterator<T> fullConstructorNameIterator<T extends MemberBuilder>() =>
      new ClassDeclarationConstructorNameIterator<SourceClassBuilder, T>(
          const _SourceClassBuilderAugmentationAccess(), this,
          includeDuplicates: false);

  /// Looks up the constructor by [name] on the class built by this class
  /// builder.
  SourceConstructorBuilder? lookupConstructor(Name name) {
    if (name.text == "new") {
      name = new Name("", name.library);
    }

    Builder? builder = nameSpace.lookupConstructor(name.text);
    if (builder is SourceConstructorBuilder) {
      return builder;
    }
    return null;
  }

  /// Looks up the super constructor by [name] on the superclass of the class
  /// built by this class builder.
  Constructor? lookupSuperConstructor(Name name) {
    if (name.text == "new") {
      name = new Name("", name.library);
    }

    Class? superclass = cls.superclass;
    if (superclass != null) {
      for (Constructor constructor in superclass.constructors) {
        if (constructor.name == name) {
          return constructor;
        }
      }
    }
    return null;
  }

  @override
  int get typeVariablesCount => typeVariables?.length ?? 0;

  @override
  List<DartType> buildAliasedTypeArguments(LibraryBuilder library,
      List<TypeBuilder>? arguments, ClassHierarchyBase? hierarchy) {
    if (arguments == null && typeVariables == null) {
      return <DartType>[];
    }

    if (arguments == null && typeVariables != null) {
      // TODO(johnniwinther): Use i2b here when needed.
      List<DartType> result = new List<DartType>.generate(
          typeVariables!.length,
          (int i) => typeVariables![i]
              .defaultType!
              // TODO(johnniwinther): Using [libraryBuilder] here instead of
              // [library] preserves the nullability of the original
              // declaration. Should we legacy erase this?
              .buildAliased(
                  libraryBuilder, TypeUse.defaultTypeAsTypeArgument, hierarchy),
          growable: true);
      return result;
    }

    if (arguments != null && arguments.length != typeVariablesCount) {
      // Coverage-ignore-block(suite): Not run.
      assert(libraryBuilder.loader.assertProblemReportedElsewhere(
          "SourceClassBuilder.buildAliasedTypeArguments: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline));
      return unhandled(
          templateTypeArgumentMismatch
              .withArguments(typeVariablesCount)
              .problemMessage,
          "buildTypeArguments",
          -1,
          null);
    }

    assert(arguments!.length == typeVariablesCount);
    List<DartType> result = new List<DartType>.generate(
        arguments!.length,
        (int i) =>
            arguments[i].buildAliased(library, TypeUse.typeArgument, hierarchy),
        growable: true);
    return result;
  }

  /// Returns a map which maps the type variables of [superclass] to their
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
          DartType argument =
              i < arguments.length ? arguments[i] : const DynamicType();
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

  @override
  void applyAugmentation(Builder augmentation) {
    if (augmentation is SourceClassBuilder) {
      augmentation.actualOrigin = this;
      (_augmentations ??= []).add(augmentation);

      mergedScope.addAugmentationScope(augmentation);

      int originLength = typeVariables?.length ?? 0;
      int augmentationLength = augmentation.typeVariables?.length ?? 0;
      if (originLength != augmentationLength) {
        // Coverage-ignore-block(suite): Not run.
        augmentation.addProblem(messagePatchClassTypeVariablesMismatch,
            augmentation.charOffset, noLength, context: [
          messagePatchClassOrigin.withLocation(fileUri, charOffset, noLength)
        ]);
      } else if (typeVariables != null) {
        int count = 0;
        for (NominalVariableBuilder t in augmentation.typeVariables!) {
          typeVariables![count++].applyAugmentation(t);
        }
      }
    } else {
      // Coverage-ignore-block(suite): Not run.
      libraryBuilder.addProblem(messagePatchDeclarationMismatch,
          augmentation.charOffset, noLength, augmentation.fileUri, context: [
        messagePatchDeclarationOrigin.withLocation(
            fileUri, charOffset, noLength)
      ]);
    }
  }

  void checkSupertypes(
      CoreTypes coreTypes,
      ClassHierarchyBuilder hierarchyBuilder,
      Class objectClass,
      Class enumClass,
      Class underscoreEnumClass,
      Class? macroClass) {
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
        bool mixedInClassIsBaseOrFinal = mixedInClass != null &&
            (mixedInClass.isBase || mixedInClass.isFinal);
        if (superclassIsBaseOrFinal || mixedInClassIsBaseOrFinal) {
          cls.isFinal = true;
        }
      }
    }

    ClassHierarchyNode classHierarchyNode =
        hierarchyBuilder.getNodeFromClass(cls);
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
          ClassHierarchyNode superclassHierarchyNode =
              hierarchyBuilder.getNodeFromClass(interfaceClass);
          for (String restrictedMemberName in restrictedNames) {
            // TODO(johnniwinther): Handle injected members.
            Builder? member = superclassHierarchyNode.classBuilder.nameSpace
                .lookupLocalMember(restrictedMemberName, setter: false);
            if (member is MemberBuilder && !member.isAbstract) {
              restrictedMembersInSuperclasses[restrictedMemberName] ??=
                  superclassHierarchyNode.classBuilder;
            }
          }
          Builder? member = superclassHierarchyNode.classBuilder.nameSpace
              .lookupLocalMember("values", setter: false);
          if (member is MemberBuilder && !member.isAbstract) {
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
        addProblem(templateEnumSupertypeOfNonAbstractClass.withArguments(name),
            charOffset, noLength);
      }

      if (hasEnumSuperinterface && cls != underscoreEnumClass) {
        // Instance members named `values` are restricted.
        Builder? customValuesDeclaration =
            nameSpace.lookupLocalMember("values", setter: false);
        if (customValuesDeclaration != null &&
            !customValuesDeclaration.isStatic) {
          // Retrieve the earliest declaration for error reporting.
          while (customValuesDeclaration?.next != null) {
            // Coverage-ignore-block(suite): Not run.
            customValuesDeclaration = customValuesDeclaration?.next;
          }
          libraryBuilder.addProblem(
              templateEnumImplementerContainsValuesDeclaration
                  .withArguments(this.name),
              customValuesDeclaration!.charOffset,
              customValuesDeclaration.fullNameForErrors.length,
              fileUri);
        }
        customValuesDeclaration =
            nameSpace.lookupLocalMember("values", setter: true);
        if (customValuesDeclaration != null &&
            !customValuesDeclaration.isStatic) {
          // Retrieve the earliest declaration for error reporting.
          while (customValuesDeclaration?.next != null) {
            // Coverage-ignore-block(suite): Not run.
            customValuesDeclaration = customValuesDeclaration?.next;
          }
          libraryBuilder.addProblem(
              templateEnumImplementerContainsValuesDeclaration
                  .withArguments(this.name),
              customValuesDeclaration!.charOffset,
              customValuesDeclaration.fullNameForErrors.length,
              fileUri);
        }
        if (superclassDeclaringConcreteValues != null) {
          libraryBuilder.addProblem(
              templateInheritedRestrictedMemberOfEnumImplementer.withArguments(
                  "values", superclassDeclaringConcreteValues.name),
              charOffset,
              noLength,
              fileUri);
        }

        // Non-setter concrete instance members named `index` and hashCode and
        // operator == are restricted.
        for (String restrictedMemberName in restrictedNames) {
          Builder? member =
              nameSpace.lookupLocalMember(restrictedMemberName, setter: false);
          if (member is MemberBuilder && !member.isAbstract) {
            libraryBuilder.addProblem(
                templateEnumImplementerContainsRestrictedInstanceDeclaration
                    .withArguments(this.name, restrictedMemberName),
                member.charOffset,
                member.fullNameForErrors.length,
                fileUri);
          }

          if (restrictedMembersInSuperclasses
              .containsKey(restrictedMemberName)) {
            ClassBuilder restrictedNameMemberProvider =
                restrictedMembersInSuperclasses[restrictedMemberName]!;
            libraryBuilder.addProblem(
                templateInheritedRestrictedMemberOfEnumImplementer
                    .withArguments(restrictedMemberName,
                        restrictedNameMemberProvider.name),
                charOffset,
                noLength,
                fileUri);
          }
        }
      }
    }
    // Coverage-ignore(suite): Not run.
    if (macroClass != null && !cls.isMacro && !cls.isAbstract) {
      // TODO(johnniwinther): Merge this check with the loop above.
      bool isMacroFound = false;
      List<Supertype> interfaces = classHierarchyNode.superclasses;
      for (int i = 0; !isMacroFound && i < interfaces.length; i++) {
        if (interfaces[i].classNode == macroClass) {
          isMacroFound = true;
        }
      }
      interfaces = classHierarchyNode.interfaces;
      for (int i = 0; !isMacroFound && i < interfaces.length; i++) {
        if (interfaces[i].classNode == macroClass) {
          isMacroFound = true;
        }
      }
      if (isMacroFound) {
        addProblem(templateMacroClassNotDeclaredMacro.withArguments(name),
            charOffset, noLength);
      }
    }

    void fail(NamedTypeBuilder target, Message message,
        TypeAliasBuilder? aliasBuilder) {
      int nameOffset = target.typeName.nameOffset;
      int nameLength = target.typeName.nameLength;
      if (aliasBuilder != null) {
        // Coverage-ignore-block(suite): Not run.
        addProblem(message, nameOffset, nameLength, context: [
          messageTypedefCause.withLocation(
              aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
        ]);
      } else {
        addProblem(message, nameOffset, nameLength);
      }
    }

    // Extract and check superclass (if it exists).
    ClassBuilder? superClass;
    TypeBuilder? superClassType = supertypeBuilder;
    if (superClassType is NamedTypeBuilder) {
      TypeDeclarationBuilder? decl = superClassType.declaration;
      TypeAliasBuilder? aliasBuilder; // Non-null if a type alias is use.
      if (decl is TypeAliasBuilder) {
        aliasBuilder = decl;
        decl = aliasBuilder.unaliasDeclaration(superClassType.typeArguments,
            isUsedAsClass: true,
            usedAsClassCharOffset: superClassType.charOffset,
            usedAsClassFileUri: superClassType.fileUri);
      }
      // TODO(eernst): Should gather 'restricted supertype' checks in one place,
      // e.g., dynamic/int/String/Null and more are checked elsewhere.
      if (decl is VoidTypeDeclarationBuilder) {
        // Coverage-ignore-block(suite): Not run.
        fail(superClassType, messageExtendsVoid, aliasBuilder);
      } else if (decl is NeverTypeDeclarationBuilder) {
        fail(superClassType, messageExtendsNever, aliasBuilder);
      } else if (decl is ClassBuilder) {
        superClass = decl;
      }
    }
    if (cls.isMixinClass) {
      // Check that the class does not have a constructor.
      Iterator<SourceMemberBuilder> constructorIterator =
          fullConstructorIterator<SourceMemberBuilder>();
      while (constructorIterator.moveNext()) {
        SourceMemberBuilder constructor = constructorIterator.current;
        // Assumes the constructor isn't synthetic since
        // [installSyntheticConstructors] hasn't been called yet.
        if (constructor is DeclaredSourceConstructorBuilder) {
          // Report an error if a mixin class has a constructor with parameters,
          // is external, or is a redirecting constructor.
          if (constructor.isRedirecting ||
              (constructor.formals != null &&
                  constructor.formals!.isNotEmpty) ||
              constructor.isExternal) {
            addProblem(
                templateIllegalMixinDueToConstructors
                    .withArguments(fullNameForErrors),
                constructor.charOffset,
                noLength);
          }
        }
      }
      // Check that the class has 'Object' as their superclass.
      if (superClass != null &&
          superClassType != null &&
          superClass.cls != objectClass) {
        addProblem(templateMixinInheritsFromNotObject.withArguments(name),
            superClassType.charOffset ?? TreeNode.noOffset, noLength);
      }
    }
    if (classHierarchyNode.isMixinApplication) {
      assert(
          mixedInTypeBuilder != null,
          // Coverage-ignore(suite): Not run.
          "No mixed in type builder for mixin application $this.");
      ClassHierarchyNode mixedInNode = classHierarchyNode.mixedInNode!;
      ClassHierarchyNode? mixinSuperClassNode =
          mixedInNode.directSuperClassNode;
      if (mixinSuperClassNode != null &&
          mixinSuperClassNode.classBuilder.cls != objectClass &&
          !mixedInNode.classBuilder.cls.isMixinDeclaration) {
        addProblem(
            templateMixinInheritsFromNotObject
                .withArguments(mixedInNode.classBuilder.name),
            mixedInTypeBuilder!.charOffset ?? TreeNode.noOffset,
            noLength);
      }
    }

    if (interfaceBuilders == null) return;

    // Validate interfaces.
    Map<ClassBuilder, int>? problems;
    Map<ClassBuilder, int>? problemsOffsets;
    Set<ClassBuilder> implemented = new Set<ClassBuilder>();
    for (TypeBuilder type in interfaceBuilders!) {
      if (type is NamedTypeBuilder) {
        int? charOffset = type.charOffset;
        TypeDeclarationBuilder? typeDeclaration = type.declaration;
        TypeDeclarationBuilder? decl;
        TypeAliasBuilder? aliasBuilder; // Non-null if a type alias is used.
        if (typeDeclaration is TypeAliasBuilder) {
          aliasBuilder = typeDeclaration;
          decl = aliasBuilder.unaliasDeclaration(type.typeArguments,
              isUsedAsClass: true,
              usedAsClassCharOffset: type.charOffset,
              usedAsClassFileUri: type.fileUri);
        } else {
          decl = typeDeclaration;
        }
        if (decl is ClassBuilder) {
          ClassBuilder interface = decl;
          if (superClass == interface) {
            addProblem(
                templateImplementsSuperClass.withArguments(interface.name),
                this.charOffset,
                noLength);
          } else if (interface.cls.name == "FutureOr" &&
              // Coverage-ignore(suite): Not run.
              interface.cls.enclosingLibrary.importUri.isScheme("dart") &&
              // Coverage-ignore(suite): Not run.
              interface.cls.enclosingLibrary.importUri.path == "async") {
            // Coverage-ignore-block(suite): Not run.
            addProblem(messageImplementsFutureOr, this.charOffset, noLength);
          } else if (implemented.contains(interface)) {
            // Aggregate repetitions.
            problems ??= <ClassBuilder, int>{};
            problems[interface] ??= 0;
            problems[interface] = problems[interface]! + 1;
            problemsOffsets ??= <ClassBuilder, int>{};
            problemsOffsets[interface] ??= charOffset ?? TreeNode.noOffset;
          } else {
            implemented.add(interface);
          }
        }
        if (decl != superClass) {
          // TODO(eernst): Have all 'restricted supertype' checks in one place.
          if (decl is VoidTypeDeclarationBuilder) {
            // Coverage-ignore-block(suite): Not run.
            fail(type, messageImplementsVoid, aliasBuilder);
          } else if (decl is NeverTypeDeclarationBuilder) {
            fail(type, messageImplementsNever, aliasBuilder);
          }
        }
      }
    }
    if (problems != null) {
      problems.forEach((ClassBuilder interface, int repetitions) {
        addProblem(
            templateImplementsRepeated.withArguments(
                interface.name, repetitions),
            problemsOffsets![interface]!,
            noLength);
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
      InterfaceType requiredInterface =
          substitution.substituteSupertype(constraint).asInterfaceType;
      InterfaceType? implementedInterface =
          hierarchy.getInterfaceTypeAsInstanceOfClass(
              supertype, requiredInterface.classNode);
      if (implementedInterface == null ||
          !typeEnvironment.areMutualSubtypes(implementedInterface,
              requiredInterface, SubtypeCheckMode.withNullabilities)) {
        libraryBuilder.addProblem(
            templateMixinApplicationIncompatibleSupertype.withArguments(
                supertype, requiredInterface, cls.mixedInType!.asInterfaceType),
            cls.fileOffset,
            noLength,
            cls.fileUri);
      }
    }
  }

  void checkRedirectingFactories(TypeEnvironment typeEnvironment) {
    Iterator<SourceFactoryBuilder> iterator =
        nameSpace.filteredConstructorIterator(
            parent: this, includeDuplicates: true, includeAugmentations: true);
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
    if (typeVariables == null) return supertype;
    Message? message;
    for (int i = 0; i < typeVariables!.length; ++i) {
      NominalVariableBuilder typeVariableBuilder = typeVariables![i];
      Variance variance = computeTypeVariableBuilderVariance(
              typeVariableBuilder, supertype,
              sourceLoader: libraryBuilder.loader)
          .variance!;
      if (!variance.greaterThanOrEqual(typeVariables![i].variance)) {
        if (typeVariables![i].parameter.isLegacyCovariant) {
          message = templateInvalidTypeVariableInSupertype.withArguments(
              typeVariables![i].name,
              variance.keyword,
              supertype.typeName!.name);
        } else {
          // Coverage-ignore-block(suite): Not run.
          message =
              templateInvalidTypeVariableInSupertypeWithVariance.withArguments(
                  typeVariables![i].variance.keyword,
                  typeVariables![i].name,
                  variance.keyword,
                  supertype.typeName!.name);
        }
        libraryBuilder.addProblem(message, charOffset, noLength, fileUri);
      }
    }
    if (message != null) {
      TypeName typeName = supertype.typeName!;
      return new NamedTypeBuilderImpl(
          typeName, const NullabilityBuilder.omitted(),
          fileUri: fileUri,
          charOffset: charOffset,
          instanceTypeVariableAccess:
              InstanceTypeVariableAccessState.Unexpected)
        ..bind(
            libraryBuilder,
            new InvalidTypeDeclarationBuilder(typeName.name,
                message.withLocation(fileUri, charOffset, noLength)));
    }
    return supertype;
  }

  void checkVarianceInField(SourceFieldBuilder fieldBuilder,
      TypeEnvironment typeEnvironment, List<TypeParameter> typeParameters) {
    for (TypeParameter typeParameter in typeParameters) {
      Variance fieldVariance =
          computeVariance(typeParameter, fieldBuilder.fieldType);
      if (fieldBuilder.isClassInstanceMember) {
        reportVariancePositionIfInvalid(fieldVariance, typeParameter,
            fieldBuilder.fileUri, fieldBuilder.charOffset);
      }
      if (fieldBuilder.isClassInstanceMember &&
          fieldBuilder.isAssignable &&
          !fieldBuilder.isCovariantByDeclaration) {
        fieldVariance = Variance.contravariant.combine(fieldVariance);
        reportVariancePositionIfInvalid(fieldVariance, typeParameter,
            fieldBuilder.fileUri, fieldBuilder.charOffset);
      }
    }
  }

  void checkVarianceInFunction(Procedure procedure,
      TypeEnvironment typeEnvironment, List<TypeParameter> typeParameters) {
    List<TypeParameter> functionTypeParameters =
        procedure.function.typeParameters;
    List<VariableDeclaration> positionalParameters =
        procedure.function.positionalParameters;
    List<VariableDeclaration> namedParameters =
        procedure.function.namedParameters;
    DartType returnType = procedure.function.returnType;

    for (TypeParameter functionParameter in functionTypeParameters) {
      for (TypeParameter typeParameter in typeParameters) {
        Variance typeVariance = Variance.invariant
            .combine(computeVariance(typeParameter, functionParameter.bound));
        reportVariancePositionIfInvalid(
            typeVariance, typeParameter, fileUri, functionParameter.fileOffset);
      }
    }
    for (VariableDeclaration formal in positionalParameters) {
      if (!formal.isCovariantByDeclaration) {
        for (TypeParameter typeParameter in typeParameters) {
          Variance formalVariance = Variance.contravariant
              .combine(computeVariance(typeParameter, formal.type));
          reportVariancePositionIfInvalid(
              formalVariance, typeParameter, fileUri, formal.fileOffset);
        }
      }
    }
    for (VariableDeclaration named in namedParameters) {
      for (TypeParameter typeParameter in typeParameters) {
        Variance namedVariance = Variance.contravariant
            .combine(computeVariance(typeParameter, named.type));
        reportVariancePositionIfInvalid(
            namedVariance, typeParameter, fileUri, named.fileOffset);
      }
    }

    for (TypeParameter typeParameter in typeParameters) {
      Variance returnTypeVariance = computeVariance(typeParameter, returnType);
      reportVariancePositionIfInvalid(returnTypeVariance, typeParameter,
          fileUri, procedure.function.fileOffset,
          isReturnType: true);
    }
  }

  void reportVariancePositionIfInvalid(Variance variance,
      TypeParameter typeParameter, Uri fileUri, int fileOffset,
      {bool isReturnType = false}) {
    SourceLibraryBuilder library = this.libraryBuilder;
    if (!typeParameter.isLegacyCovariant &&
        !variance.greaterThanOrEqual(typeParameter.variance)) {
      // Coverage-ignore-block(suite): Not run.
      Message message;
      if (isReturnType) {
        message = templateInvalidTypeVariableVariancePositionInReturnType
            .withArguments(typeParameter.variance.keyword, typeParameter.name!,
                variance.keyword);
      } else {
        message = templateInvalidTypeVariableVariancePosition.withArguments(
            typeParameter.variance.keyword,
            typeParameter.name!,
            variance.keyword);
      }
      library.reportTypeArgumentIssue(message, fileUri, fileOffset,
          typeParameter: typeParameter);
    }
  }

  void checkTypesInOutline(TypeEnvironment typeEnvironment) {
    Iterator<SourceMemberBuilder> memberIterator =
        fullMemberIterator<SourceMemberBuilder>();
    while (memberIterator.moveNext()) {
      SourceMemberBuilder builder = memberIterator.current;
      builder.checkVariance(this, typeEnvironment);
      builder.checkTypes(libraryBuilder, typeEnvironment);
    }

    Iterator<SourceMemberBuilder> constructorIterator =
        fullConstructorIterator<SourceMemberBuilder>();
    while (constructorIterator.moveNext()) {
      SourceMemberBuilder builder = constructorIterator.current;
      builder.checkTypes(libraryBuilder, typeEnvironment);
    }
  }

  void addSyntheticConstructor(
      SyntheticSourceConstructorBuilder constructorBuilder) {
    String name = constructorBuilder.name;
    constructorBuilder.next = nameSpace.lookupConstructor(name);
    nameSpace.addConstructor(name, constructorBuilder);
    // Synthetic constructors are created after the component has been built
    // so we need to add the constructor to the class.
    cls.addConstructor(constructorBuilder.invokeTarget);
    if (constructorBuilder.readTarget != constructorBuilder.invokeTarget) {
      cls.addProcedure(constructorBuilder.readTarget as Procedure);
    }
    if (constructorBuilder.isConst) {
      cls.hasConstConstructor = true;
    }
  }

  int buildBodyNodes() {
    adjustAnnotationFileUri(cls, cls.fileUri);

    int count = 0;

    void buildMembers(Builder builder) {
      if (builder.parent != this) {
        return;
      }
      if (builder is SourceMemberBuilder) {
        count += builder.buildBodyNodes((
            {required Member member,
            Member? tearOff,
            required BuiltMemberKind kind}) {
          _addMemberToClass(builder, member);
          if (tearOff != null) {
            // Coverage-ignore-block(suite): Not run.
            _addMemberToClass(builder, tearOff);
          }
        });
      }
    }

    nameSpace
        .filteredIterator(
            parent: this, includeDuplicates: true, includeAugmentations: true)
        .forEach(buildMembers);
    nameSpace
        .filteredConstructorIterator(
            parent: this, includeDuplicates: true, includeAugmentations: true)
        .forEach(buildMembers);
    return count;
  }

  void _addMemberToClass(SourceMemberBuilder memberBuilder, Member member) {
    member.parent = cls;
    if (!memberBuilder.isAugmenting &&
        !memberBuilder.isDuplicate &&
        !memberBuilder.isConflictingSetter) {
      if (memberBuilder.isConflictingAugmentationMember) {
        if (member is Field &&
                // Coverage-ignore(suite): Not run.
                member.isStatic ||
            member is Procedure && member.isStatic) {
          member.name = new Name(
              '${member.name}'
              '#${memberBuilder.libraryBuilder.augmentationIndex}',
              member.name.library);
        } else {
          return;
        }
      }

      if (member is Procedure) {
        cls.addProcedure(member);
      } else if (member is Field) {
        cls.addField(member);
      } else if (member is Constructor) {
        cls.addConstructor(member);
      } else {
        unhandled("${member.runtimeType}", "getMember", member.fileOffset,
            member.fileUri);
      }
    }
  }

  /// Return a map whose keys are the supertypes of this [SourceClassBuilder]
  /// after expansion of type aliases, if any. For each supertype key, the
  /// corresponding value is the type alias which was unaliased in order to
  /// find the supertype, or null if the supertype was not aliased.
  Map<TypeDeclarationBuilder?, TypeAliasBuilder?> computeDirectSupertypes(
      ClassBuilder objectClass) {
    final Map<TypeDeclarationBuilder?, TypeAliasBuilder?> result = {};
    final TypeBuilder? supertype = this.supertypeBuilder;
    if (supertype != null) {
      TypeDeclarationBuilder? declarationBuilder = supertype.declaration;
      if (declarationBuilder is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = declarationBuilder;
        NamedTypeBuilder namedBuilder = supertype as NamedTypeBuilder;
        declarationBuilder = aliasBuilder.unaliasDeclaration(
            namedBuilder.typeArguments,
            isUsedAsClass: true,
            usedAsClassCharOffset: namedBuilder.charOffset,
            usedAsClassFileUri: namedBuilder.fileUri);
        result[declarationBuilder] = aliasBuilder;
      } else {
        result[declarationBuilder] = null;
      }
    } else if (objectClass != this) {
      result[objectClass] = null;
    }
    final List<TypeBuilder>? interfaces = this.interfaceBuilders;
    if (interfaces != null) {
      for (int i = 0; i < interfaces.length; i++) {
        TypeBuilder interface = interfaces[i];
        TypeDeclarationBuilder? declarationBuilder = interface.declaration;
        if (declarationBuilder is TypeAliasBuilder) {
          TypeAliasBuilder aliasBuilder = declarationBuilder;
          NamedTypeBuilder namedBuilder = interface as NamedTypeBuilder;
          declarationBuilder = aliasBuilder.unaliasDeclaration(
              namedBuilder.typeArguments,
              isUsedAsClass: true,
              usedAsClassCharOffset: namedBuilder.charOffset,
              usedAsClassFileUri: namedBuilder.fileUri);
          result[declarationBuilder] = aliasBuilder;
        } else {
          result[declarationBuilder] = null;
        }
      }
    }
    final TypeBuilder? mixedInTypeBuilder = this.mixedInTypeBuilder;
    if (mixedInTypeBuilder != null) {
      TypeDeclarationBuilder? declarationBuilder =
          mixedInTypeBuilder.declaration;
      if (declarationBuilder is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = declarationBuilder;
        NamedTypeBuilder namedBuilder = mixedInTypeBuilder as NamedTypeBuilder;
        declarationBuilder = aliasBuilder.unaliasDeclaration(
            namedBuilder.typeArguments,
            isUsedAsClass: true,
            usedAsClassCharOffset: namedBuilder.charOffset,
            usedAsClassFileUri: namedBuilder.fileUri);
        result[declarationBuilder] = aliasBuilder;
      } else {
        result[declarationBuilder] = null;
      }
    }
    return result;
  }

  @override
  int compareTo(SourceClassBuilder other) {
    int result = "$fileUri".compareTo("${other.fileUri}");
    if (result != 0) return result;
    return charOffset.compareTo(other.charOffset);
  }

  void _handleSeenCovariant(
      ClassHierarchyMembers memberHierarchy,
      Member interfaceMember,
      bool isSetter,
      callback(Member interfaceMember, bool isSetter)) {
    // When a parameter is covariant we have to check that we also
    // override the same member in all parents.
    for (Supertype supertype in interfaceMember.enclosingClass!.supers) {
      Member? member = memberHierarchy.getInterfaceMember(
          supertype.classNode, interfaceMember.name,
          setter: isSetter);
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
      callback(Member interfaceMember, bool isSetter),
      {required bool isInterfaceCheck}) {
    if (declaredMember == interfaceMember) {
      return;
    }
    Member interfaceMemberOrigin =
        interfaceMember.memberSignatureOrigin ?? interfaceMember;
    if (declaredMember is Constructor || interfaceMember is Constructor) {
      unimplemented(
          "Constructor in override check.", declaredMember.fileOffset, fileUri);
    }
    if (declaredMember is Procedure && interfaceMember is Procedure) {
      if (declaredMember.kind == interfaceMember.kind) {
        if (declaredMember.kind == ProcedureKind.Method ||
            declaredMember.kind == ProcedureKind.Operator) {
          bool seenCovariant = checkMethodOverride(types, declaredMember,
              interfaceMember, interfaceMemberOrigin, isInterfaceCheck);
          if (seenCovariant) {
            _handleSeenCovariant(
                memberHierarchy, interfaceMember, isSetter, callback);
          }
        } else if (declaredMember.kind == ProcedureKind.Getter) {
          checkGetterOverride(types, declaredMember, interfaceMember,
              interfaceMemberOrigin, isInterfaceCheck);
        } else if (declaredMember.kind == ProcedureKind.Setter) {
          bool seenCovariant = checkSetterOverride(types, declaredMember,
              interfaceMember, interfaceMemberOrigin, isInterfaceCheck);
          if (seenCovariant) {
            _handleSeenCovariant(
                memberHierarchy, interfaceMember, isSetter, callback);
          }
        } else {
          // Coverage-ignore-block(suite): Not run.
          assert(
              false,
              "Unexpected procedure kind in override check: "
              "${declaredMember.kind}");
        }
      }
    } else {
      bool declaredMemberHasGetter = declaredMember is Field ||
          declaredMember is Procedure && declaredMember.isGetter;
      bool interfaceMemberHasGetter = interfaceMember is Field ||
          interfaceMember is Procedure && interfaceMember.isGetter;
      bool declaredMemberHasSetter = (declaredMember is Field &&
              !declaredMember.isFinal &&
              !declaredMember.isConst) ||
          declaredMember is Procedure && declaredMember.isSetter;
      bool interfaceMemberHasSetter = (interfaceMember is Field &&
              !interfaceMember.isFinal &&
              !interfaceMember.isConst) ||
          interfaceMember is Procedure && interfaceMember.isSetter;
      if (declaredMemberHasGetter && interfaceMemberHasGetter) {
        checkGetterOverride(types, declaredMember, interfaceMember,
            interfaceMemberOrigin, isInterfaceCheck);
      }
      if (declaredMemberHasSetter && interfaceMemberHasSetter) {
        bool seenCovariant = checkSetterOverride(types, declaredMember,
            interfaceMember, interfaceMemberOrigin, isInterfaceCheck);
        if (seenCovariant) {
          _handleSeenCovariant(
              memberHierarchy, interfaceMember, isSetter, callback);
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
      bool isInterfaceCheck) {
    Substitution? interfaceSubstitution;
    if (interfaceMember.enclosingClass!.typeParameters.isNotEmpty) {
      Class enclosingClass = interfaceMember.enclosingClass!;
      interfaceSubstitution = Substitution.fromPairs(
          enclosingClass.typeParameters,
          types.hierarchy.getInterfaceTypeArgumentsAsInstanceOfClass(
              thisType, enclosingClass)!);
    }

    if (declaredFunction?.typeParameters.length !=
        interfaceFunction?.typeParameters.length) {
      reportInvalidOverride(
          isInterfaceCheck,
          declaredMember,
          templateOverrideTypeVariablesMismatch.withArguments(
              "${declaredMember.enclosingClass!.name}."
                  "${declaredMember.name.text}",
              "${interfaceMemberOrigin.enclosingClass!.name}."
                  "${interfaceMemberOrigin.name.text}"),
          declaredMember.fileOffset,
          noLength,
          context: [
            templateOverriddenMethodCause
                .withArguments(interfaceMemberOrigin.name.text)
                .withLocation(_getMemberUri(interfaceMemberOrigin),
                    interfaceMemberOrigin.fileOffset, noLength)
          ]);
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
        FreshTypeParameters freshTypeParameters =
            getFreshTypeParameters(interfaceFunction!.typeParameters);
        interfaceTypeParameters = freshTypeParameters.freshTypeParameters;
        for (TypeParameter parameter in interfaceTypeParameters) {
          parameter.bound =
              interfaceSubstitution.substituteType(parameter.bound);
        }
        updateBoundNullabilities(interfaceTypeParameters);
      }

      Substitution substitution;
      if (declaredFunction!.typeParameters.isEmpty) {
        substitution = Substitution.empty;
      } else if (declaredFunction.typeParameters.length == 1) {
        substitution = Substitution.fromSingleton(
            interfaceFunction.typeParameters[0],
            new TypeParameterType.forAlphaRenaming(interfaceTypeParameters[0],
                declaredFunction.typeParameters[0]));
      } else {
        Map<TypeParameter, DartType> substitutionMap =
            <TypeParameter, DartType>{};
        for (int i = 0; i < declaredFunction.typeParameters.length; ++i) {
          substitutionMap[interfaceFunction.typeParameters[i]] =
              new TypeParameterType.forAlphaRenaming(interfaceTypeParameters[i],
                  declaredFunction.typeParameters[i]);
        }
        substitution = Substitution.fromMap(substitutionMap);
      }
      for (int i = 0; i < declaredFunction.typeParameters.length; ++i) {
        TypeParameter declaredParameter = declaredFunction.typeParameters[i];
        TypeParameter interfaceParameter = interfaceFunction.typeParameters[i];
        if (!interfaceParameter.isCovariantByClass) {
          DartType declaredBound = declaredParameter.bound;
          DartType interfaceBound = interfaceParameter.bound;
          if (interfaceSubstitution != null) {
            declaredBound = interfaceSubstitution.substituteType(declaredBound);
            interfaceBound =
                interfaceSubstitution.substituteType(interfaceBound);
          }
          DartType computedBound = substitution.substituteType(interfaceBound);
          if (!types
              .performNullabilityAwareMutualSubtypesCheck(
                  declaredBound, computedBound)
              .isSubtypeWhenUsingNullabilities()) {
            // Coverage-ignore-block(suite): Not run.
            reportInvalidOverride(
                isInterfaceCheck,
                declaredMember,
                templateOverrideTypeVariablesBoundMismatch.withArguments(
                    declaredBound,
                    declaredParameter.name!,
                    "${declaredMember.enclosingClass!.name}."
                        "${declaredMember.name.text}",
                    computedBound,
                    "${interfaceMemberOrigin.enclosingClass!.name}."
                        "${interfaceMemberOrigin.name.text}"),
                declaredMember.fileOffset,
                noLength,
                context: [
                  templateOverriddenMethodCause
                      .withArguments(interfaceMemberOrigin.name.text)
                      .withLocation(_getMemberUri(interfaceMemberOrigin),
                          interfaceMemberOrigin.fileOffset, noLength)
                ]);
          }
        }
      }
      if (interfaceSubstitution != null) {
        interfaceSubstitution =
            Substitution.combine(interfaceSubstitution, substitution);
      } else {
        interfaceSubstitution = substitution;
      }
    }
    return interfaceSubstitution;
  }

  Substitution? _computeDeclaredSubstitution(
      Types types, Member declaredMember) {
    Substitution? declaredSubstitution;
    if (declaredMember.enclosingClass!.typeParameters.isNotEmpty) {
      Class enclosingClass = declaredMember.enclosingClass!;
      declaredSubstitution = Substitution.fromPairs(
          enclosingClass.typeParameters,
          types.hierarchy.getInterfaceTypeArgumentsAsInstanceOfClass(
              thisType, enclosingClass)!);
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
      bool isInterfaceCheck,
      {bool asIfDeclaredParameter = false}) {
    if (interfaceSubstitution != null) {
      interfaceType = interfaceSubstitution.substituteType(interfaceType);
    }
    if (declaredSubstitution != null) {
      declaredType = declaredSubstitution.substituteType(declaredType);
    }

    bool inParameter = declaredParameter != null || asIfDeclaredParameter;
    DartType subtype = inParameter ? interfaceType : declaredType;
    DartType supertype = inParameter ? declaredType : interfaceType;

    if (types.isSubtypeOf(
        subtype, supertype, SubtypeCheckMode.withNullabilities)) {
      // No problem--the proper subtyping relation is satisfied.
    } else if (isCovariantByDeclaration &&
        types.isSubtypeOf(
            supertype, subtype, SubtypeCheckMode.withNullabilities)) {
      // No problem--the overriding parameter is marked "covariant" and has
      // a type which is a subtype of the parameter it overrides.
    } else if (subtype is InvalidType || supertype is InvalidType) {
      // Don't report a problem as something else is wrong that has already
      // been reported.
    } else {
      // Report an error.
      String declaredMemberName = '${declaredMember.enclosingClass!.name}'
          '.${declaredMember.name.text}';
      String interfaceMemberName =
          '${interfaceMemberOrigin.enclosingClass!.name}'
          '.${interfaceMemberOrigin.name.text}';
      Message message;
      int fileOffset;
      if (declaredParameter == null) {
        if (asIfDeclaredParameter) {
          // Setter overridden by field
          message = templateOverrideTypeMismatchSetter.withArguments(
              declaredMemberName,
              declaredType,
              interfaceType,
              interfaceMemberName);
        } else {
          message = templateOverrideTypeMismatchReturnType.withArguments(
              declaredMemberName,
              declaredType,
              interfaceType,
              interfaceMemberName);
        }
        fileOffset = declaredMember.fileOffset;
      } else {
        message = templateOverrideTypeMismatchParameter.withArguments(
            declaredParameter.name!,
            declaredMemberName,
            declaredType,
            interfaceType,
            interfaceMemberName);
        fileOffset = declaredParameter.fileOffset;
      }
      reportInvalidOverride(
          isInterfaceCheck, declaredMember, message, fileOffset, noLength,
          context: [
            templateOverriddenMethodCause
                .withArguments(interfaceMemberOrigin.name.text)
                .withLocation(_getMemberUri(interfaceMemberOrigin),
                    interfaceMemberOrigin.fileOffset, noLength)
          ]);
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
      bool isInterfaceCheck) {
    assert(declaredMember.kind == interfaceMember.kind);
    assert(declaredMember.kind == ProcedureKind.Method ||
        declaredMember.kind == ProcedureKind.Operator);
    bool seenCovariant = false;
    FunctionNode declaredFunction = declaredMember.function;
    FunctionType? declaredSignatureType = declaredMember.signatureType;
    FunctionNode interfaceFunction = interfaceMember.function;
    FunctionType? interfaceSignatureType = interfaceMember.signatureType;

    Substitution? interfaceSubstitution = _computeInterfaceSubstitution(
        types,
        declaredMember,
        interfaceMember,
        interfaceMemberOrigin,
        declaredFunction,
        interfaceFunction,
        isInterfaceCheck);

    Substitution? declaredSubstitution =
        _computeDeclaredSubstitution(types, declaredMember);

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
        isInterfaceCheck);
    if (declaredFunction.positionalParameters.length <
        interfaceFunction.positionalParameters.length) {
      reportInvalidOverride(
          isInterfaceCheck,
          declaredMember,
          templateOverrideFewerPositionalArguments.withArguments(
              "${declaredMember.enclosingClass!.name}."
                  "${declaredMember.name.text}",
              "${interfaceMemberOrigin.enclosingClass!.name}."
                  "${interfaceMemberOrigin.name.text}"),
          declaredMember.fileOffset,
          noLength,
          context: [
            templateOverriddenMethodCause
                .withArguments(interfaceMemberOrigin.name.text)
                .withLocation(interfaceMemberOrigin.fileUri,
                    interfaceMemberOrigin.fileOffset, noLength)
          ]);
    }
    if (interfaceFunction.requiredParameterCount <
        declaredFunction.requiredParameterCount) {
      reportInvalidOverride(
          isInterfaceCheck,
          declaredMember,
          templateOverrideMoreRequiredArguments.withArguments(
              "${declaredMember.enclosingClass!.name}."
                  "${declaredMember.name.text}",
              "${interfaceMemberOrigin.enclosingClass!.name}."
                  "${interfaceMemberOrigin.name.text}"),
          declaredMember.fileOffset,
          noLength,
          context: [
            templateOverriddenMethodCause
                .withArguments(interfaceMemberOrigin.name.text)
                .withLocation(interfaceMemberOrigin.fileUri,
                    interfaceMemberOrigin.fileOffset, noLength)
          ]);
    }
    for (int i = 0;
        i < declaredFunction.positionalParameters.length &&
            i < interfaceFunction.positionalParameters.length;
        i++) {
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
          isInterfaceCheck);
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
          templateOverrideFewerNamedArguments.withArguments(
              "${declaredMember.enclosingClass!.name}."
                  "${declaredMember.name.text}",
              "${interfaceMemberOrigin.enclosingClass!.name}."
                  "${interfaceMemberOrigin.name.text}"),
          declaredMember.fileOffset,
          noLength,
          context: [
            templateOverriddenMethodCause
                .withArguments(interfaceMemberOrigin.name.text)
                .withLocation(interfaceMemberOrigin.fileUri,
                    interfaceMemberOrigin.fileOffset, noLength)
          ]);
    }

    int compareNamedParameters(VariableDeclaration p0, VariableDeclaration p1) {
      return p0.name!.compareTo(p1.name!);
    }

    List<VariableDeclaration> sortedFromDeclared =
        new List.of(declaredFunction.namedParameters)
          ..sort(compareNamedParameters);
    List<VariableDeclaration> sortedFromInterface =
        new List.of(interfaceFunction.namedParameters)
          ..sort(compareNamedParameters);
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
          // Coverage-ignore-block(suite): Not run.
          reportInvalidOverride(
              isInterfaceCheck,
              declaredMember,
              templateOverrideMismatchNamedParameter.withArguments(
                  "${declaredMember.enclosingClass!.name}."
                      "${declaredMember.name.text}",
                  interfaceNamedParameters.current.name!,
                  "${interfaceMember.enclosingClass!.name}."
                      "${interfaceMember.name.text}"),
              declaredMember.fileOffset,
              noLength,
              context: [
                templateOverriddenMethodCause
                    .withArguments(interfaceMember.name.text)
                    .withLocation(interfaceMember.fileUri,
                        interfaceMember.fileOffset, noLength)
              ]);
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
          isInterfaceCheck);
      if (declaredParameter.isRequired &&
          !interfaceNamedParameters.current.isRequired) {
        // Coverage-ignore-block(suite): Not run.
        reportInvalidOverride(
            isInterfaceCheck,
            declaredMember,
            templateOverrideMismatchRequiredNamedParameter.withArguments(
                declaredParameter.name!,
                "${declaredMember.enclosingClass!.name}."
                    "${declaredMember.name.text}",
                "${interfaceMember.enclosingClass!.name}."
                    "${interfaceMember.name.text}"),
            declaredParameter.fileOffset,
            noLength,
            context: [
              templateOverriddenMethodCause
                  .withArguments(interfaceMemberOrigin.name.text)
                  .withLocation(_getMemberUri(interfaceMemberOrigin),
                      interfaceMemberOrigin.fileOffset, noLength)
            ]);
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
      bool isInterfaceCheck) {
    Substitution? interfaceSubstitution = _computeInterfaceSubstitution(
        types,
        declaredMember,
        interfaceMember,
        interfaceMemberOrigin,
        /* declaredFunction = */
        null,
        /* interfaceFunction = */
        null,
        isInterfaceCheck);
    Substitution? declaredSubstitution =
        _computeDeclaredSubstitution(types, declaredMember);
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
        isInterfaceCheck);
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
      bool isInterfaceCheck) {
    Substitution? interfaceSubstitution = _computeInterfaceSubstitution(
        types,
        declaredMember,
        interfaceMember,
        interfaceMemberOrigin,
        /* declaredFunction = */
        null,
        /* interfaceFunction = */
        null,
        isInterfaceCheck);
    Substitution? declaredSubstitution =
        _computeDeclaredSubstitution(types, declaredMember);
    DartType declaredType = declaredMember.setterType;
    DartType interfaceType = interfaceMember.setterType;
    VariableDeclaration? declaredParameter =
        declaredMember.function?.positionalParameters.elementAt(0);
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
        asIfDeclaredParameter: true);
    return isCovariantByDeclaration;
  }

  // When the overriding member is inherited, report the class containing
  // the conflict as the main error.
  void reportInvalidOverride(bool isInterfaceCheck, Member declaredMember,
      Message message, int fileOffset, int length,
      {List<LocatedMessage>? context}) {
    if (shouldOverrideProblemBeOverlooked(this)) {
      return;
    }

    if (declaredMember.enclosingClass == cls) {
      // Ordinary override
      libraryBuilder.addProblem(
          message, fileOffset, length, declaredMember.fileUri,
          context: context);
    } else {
      context = [
        message.withLocation(declaredMember.fileUri, fileOffset, length),
        ...?context
      ];
      if (isInterfaceCheck) {
        // Interface check
        libraryBuilder.addProblem(
            templateInterfaceCheck.withArguments(
                declaredMember.name.text, cls.name),
            cls.fileOffset,
            cls.name.length,
            cls.fileUri,
            context: context);
      } else {
        if (cls.isAnonymousMixin) {
          // Implicit mixin application class
          String baseName = cls.superclass!.demangledName;
          String mixinName = cls.mixedInClass!.name;
          int classNameLength = cls.nameAsMixinApplicationSubclass.length;
          libraryBuilder.addProblem(
              templateImplicitMixinOverride.withArguments(
                  mixinName, baseName, declaredMember.name.text),
              cls.fileOffset,
              classNameLength,
              cls.fileUri,
              context: context);
        } else {
          // Named mixin application class
          libraryBuilder.addProblem(
              templateNamedMixinOverride.withArguments(
                  cls.name, declaredMember.name.text),
              cls.fileOffset,
              cls.name.length,
              cls.fileUri,
              context: context);
        }
      }
    }
  }

  // Coverage-ignore(suite): Not run.
  /// Returns an iterator the origin class and all augmentations in application
  /// order.
  Iterator<SourceClassBuilder> get declarationIterator =>
      new AugmentationIterator<SourceClassBuilder>(
          origin, origin._augmentations);
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

class _SourceClassBuilderAugmentationAccess
    implements ClassDeclarationAugmentationAccess<SourceClassBuilder> {
  const _SourceClassBuilderAugmentationAccess();

  @override
  SourceClassBuilder getOrigin(SourceClassBuilder classDeclaration) =>
      classDeclaration.origin;

  @override
  Iterable<SourceClassBuilder>? getAugmentations(
          SourceClassBuilder classDeclaration) =>
      classDeclaration._augmentations;
}
