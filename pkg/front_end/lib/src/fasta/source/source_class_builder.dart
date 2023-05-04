// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_class_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClassHierarchyBase, ClassHierarchyMembers;
import 'package:kernel/core_types.dart';
import 'package:kernel/reference_from_index.dart' show IndexedClass;
import 'package:kernel/src/bounds_checks.dart';
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/src/types.dart' show Types;
import 'package:kernel/type_algebra.dart'
    show
        FreshTypeParameters,
        Substitution,
        getFreshTypeParameters,
        substitute,
        updateBoundNullabilities;
import 'package:kernel/type_environment.dart';

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/function_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/named_type_builder.dart';
import '../builder/never_type_declaration_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/type_variable_builder.dart';
import '../builder/void_type_declaration_builder.dart';
import '../dill/dill_member_builder.dart';
import '../fasta_codes.dart';
import '../identifiers.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/hierarchy/hierarchy_builder.dart';
import '../kernel/hierarchy/hierarchy_node.dart';
import '../kernel/kernel_helper.dart';
import 'package:kernel/src/redirecting_factory_body.dart'
    show RedirectingFactoryBody, redirectingName;
import '../kernel/type_algorithms.dart' show computeTypeVariableBuilderVariance;
import '../kernel/utils.dart' show compareProcedures;
import '../names.dart' show equalsName;
import '../problems.dart' show unexpected, unhandled, unimplemented;
import '../scope.dart';
import '../type_inference/type_schema.dart';
import '../util/helpers.dart';
import 'class_declaration.dart';
import 'source_constructor_builder.dart';
import 'source_factory_builder.dart';
import 'source_field_builder.dart';
import 'source_library_builder.dart';
import 'source_member_builder.dart';

Class initializeClass(
    Class? cls,
    List<TypeVariableBuilder>? typeVariables,
    String name,
    SourceLibraryBuilder parent,
    int startCharOffset,
    int charOffset,
    int charEndOffset,
    IndexedClass? referencesFrom,
    {required bool isAugmentation}) {
  cls ??= new Class(
      name: name,
      typeParameters:
          TypeVariableBuilder.typeParametersFromBuilders(typeVariables),
      // If the class is an augmentation class it shouldn't use the reference
      // from index even when available.
      // TODO(johnniwinther): Avoid creating [Class] so early in the builder
      // that we end up creating unneeded nodes.
      reference: isAugmentation ? null : referencesFrom?.cls.reference,
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
    implements Comparable<SourceClassBuilder>, ClassDeclaration {
  final Class actualCls;

  final List<ConstructorReferenceBuilder>? constructorReferences;

  @override
  TypeBuilder? mixedInTypeBuilder;

  final IndexedClass? referencesFromIndexed;

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

  @override
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
    assert(_isConflictingAugmentationMember == null,
        '$this.isConflictingAugmentationMember has already been fixed.');
    _isConflictingAugmentationMember = value;
  }

  List<SourceClassBuilder>? _patches;

  MergedClassMemberScope? _mergedScope;

  SourceClassBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      String name,
      List<TypeVariableBuilder>? typeVariables,
      TypeBuilder? supertype,
      List<TypeBuilder>? interfaces,
      List<TypeBuilder>? onTypes,
      Scope scope,
      ConstructorScope constructors,
      SourceLibraryBuilder parent,
      this.constructorReferences,
      int startCharOffset,
      int nameOffset,
      int charEndOffset,
      this.referencesFromIndexed,
      {Class? cls,
      this.mixedInTypeBuilder,
      this.isMixinDeclaration = false,
      this.isMacro = false,
      this.isSealed = false,
      this.isBase = false,
      this.isInterface = false,
      this.isFinal = false,
      this.isAugmentation = false,
      this.isMixinClass = false})
      : actualCls = initializeClass(cls, typeVariables, name, parent,
            startCharOffset, nameOffset, charEndOffset, referencesFromIndexed,
            isAugmentation: isAugmentation),
        super(metadata, modifiers, name, typeVariables, supertype, interfaces,
            onTypes, scope, constructors, parent, nameOffset) {
    actualCls.hasConstConstructor = declaresConstConstructor;
  }

  MergedClassMemberScope get mergedScope => _mergedScope ??=
      isPatch ? origin.mergedScope : new MergedClassMemberScope(this);

  List<SourceClassBuilder>? get patchesForTesting => _patches;

  SourceClassBuilder? actualOrigin;

  @override
  SourceClassBuilder get origin => actualOrigin ?? this;

  @override
  Class get cls => origin.actualCls;

  @override
  SourceLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as SourceLibraryBuilder;

  Class build(LibraryBuilder coreLibrary) {
    SourceLibraryBuilder.checkMemberConflicts(libraryBuilder, scope,
        // These checks are performed as part of the class hierarchy
        // computation.
        checkForInstanceVsStaticConflict: false,
        checkForMethodVsSetterConflict: false);

    void buildBuilders(Builder declaration) {
      if (declaration.parent != this) {
        if (declaration.parent?.origin != origin) {
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
        memberBuilder
            .buildOutlineNodes((Member member, BuiltMemberKind memberKind) {
          _addMemberToClass(declaration, member, memberKind);
        });
      } else {
        unhandled("${declaration.runtimeType}", "buildBuilders",
            declaration.charOffset, declaration.fileUri);
      }
    }

    scope.unfilteredIterator.forEach(buildBuilders);
    constructorScope.unfilteredIterator.forEach(buildBuilders);
    if (supertypeBuilder != null) {
      supertypeBuilder = _checkSupertype(supertypeBuilder!);
    }
    Supertype? supertype = supertypeBuilder?.buildSupertype(libraryBuilder);
    if (_isFunction(supertype, coreLibrary)) {
      supertype = null;
      supertypeBuilder = null;
    }
    if (!isMixinDeclaration &&
        actualCls.supertype != null &&
        actualCls.superclass!.isMixinDeclaration) {
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
    if (_isFunction(mixedInType, coreLibrary)) {
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
    cls.isMacro = isMacro;
    cls.isMixinClass = isMixinClass;
    cls.isSealed = isSealed;
    cls.isBase = isBase;
    cls.isInterface = isInterface;
    cls.isFinal = isFinal;

    if (interfaceBuilders != null) {
      for (int i = 0; i < interfaceBuilders!.length; ++i) {
        interfaceBuilders![i] = _checkSupertype(interfaceBuilders![i]);
        Supertype? supertype =
            interfaceBuilders![i].buildSupertype(libraryBuilder);
        if (supertype != null) {
          if (_isFunction(supertype, coreLibrary)) {
            continue;
          }
          // TODO(ahe): Report an error if supertype is null.
          actualCls.implementedTypes.add(supertype);
        }
      }
    }

    NameIterator<MemberBuilder> iterator =
        constructorScope.filteredNameIterator(
            includeDuplicates: false, includeAugmentations: true);
    while (iterator.moveNext()) {
      String name = iterator.name;
      MemberBuilder constructor = iterator.current;
      Builder? member = scope.lookupLocalMember(name, setter: false);
      if (member == null) continue;
      if (!member.isStatic) continue;
      // TODO(ahe): Revisit these messages. It seems like the last two should
      // be `context` parameter to this message.
      addProblem(templateConflictsWithMember.withArguments(name),
          constructor.charOffset, noLength);
      if (constructor.isFactory) {
        addProblem(
            templateConflictsWithFactory.withArguments("${this.name}.${name}"),
            member.charOffset,
            noLength);
      } else {
        addProblem(
            templateConflictsWithConstructor
                .withArguments("${this.name}.${name}"),
            member.charOffset,
            noLength);
      }
    }

    scope.forEachLocalSetter((String name, Builder setter) {
      Builder? constructor = constructorScope.lookupLocalMember(name);
      if (constructor == null || !setter.isStatic) return;
      addProblem(templateConflictsWithConstructor.withArguments(name),
          setter.charOffset, noLength);
      addProblem(templateConflictsWithSetter.withArguments(name),
          constructor.charOffset, noLength);
    });

    cls.procedures.sort(compareProcedures);
    return cls;
  }

  bool _isFunction(Supertype? supertype, LibraryBuilder coreLibrary) {
    if (supertype != null) {
      Class superclass = supertype.classNode;
      if (superclass.name == 'Function' &&
          // We use `superclass.parent` here instead of
          // `superclass.enclosingLibrary` to handle platform compilation. If
          // we are currently compiling the platform, the enclosing library of
          // `Function` has not yet been set, so the accessing
          // `enclosingLibrary` would result in a cast error. We assume that the
          // SDK does not contain this error, which we otherwise not find. If we
          // are _not_ compiling the platform, the `superclass.parent` has been
          // set, if it is `Function` from `dart:core`.
          superclass.parent == coreLibrary.library) {
        return true;
      }
    }
    return false;
  }

  BodyBuilderContext get bodyBuilderContext =>
      new ClassBodyBuilderContext(this);

  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    void build(Builder declaration) {
      SourceMemberBuilder member = declaration as SourceMemberBuilder;
      member.buildOutlineExpressions(
          classHierarchy, delayedActionPerformers, delayedDefaultValueCloners);
    }

    MetadataBuilder.buildAnnotations(isPatch ? origin.cls : cls, metadata,
        bodyBuilderContext, libraryBuilder, fileUri, libraryBuilder.scope);
    if (typeVariables != null) {
      for (int i = 0; i < typeVariables!.length; i++) {
        typeVariables![i].buildOutlineExpressions(
            libraryBuilder,
            bodyBuilderContext,
            classHierarchy,
            delayedActionPerformers,
            scope.parent!);
      }
    }

    constructorScope
        .filteredIterator(
            parent: this, includeDuplicates: false, includeAugmentations: true)
        .forEach(build);
    scope
        .filteredIterator(
            parent: this, includeDuplicates: false, includeAugmentations: true)
        .forEach(build);
  }

  @override
  Iterator<T> fullMemberIterator<T extends Builder>() =>
      new ClassDeclarationMemberIterator<SourceClassBuilder, T>(
          const _SourceClassBuilderAugmentationAccess(), this,
          includeDuplicates: false);

  @override
  NameIterator<T> fullMemberNameIterator<T extends Builder>() =>
      new ClassDeclarationMemberNameIterator<SourceClassBuilder, T>(
          const _SourceClassBuilderAugmentationAccess(), this,
          includeDuplicates: false);

  @override
  Iterator<T> fullConstructorIterator<T extends MemberBuilder>() =>
      new ClassDeclarationConstructorIterator<SourceClassBuilder, T>(
          const _SourceClassBuilderAugmentationAccess(), this,
          includeDuplicates: false);

  @override
  NameIterator<T> fullConstructorNameIterator<T extends MemberBuilder>() =>
      new ClassDeclarationConstructorNameIterator<SourceClassBuilder, T>(
          const _SourceClassBuilderAugmentationAccess(), this,
          includeDuplicates: false);

  @override
  bool get hasGenerativeConstructor =>
      fullConstructorNameIterator<SourceConstructorBuilder>().moveNext();

  /// Looks up the constructor by [name] on the class built by this class
  /// builder.
  ///
  /// If [isSuper] is `true`, constructors in the superclass are searched.
  Constructor? lookupConstructor(Name name, {bool isSuper = false}) {
    if (name.text == "new") {
      name = new Name("", name.library);
    }

    Class? instanceClass = cls;
    if (isSuper) {
      instanceClass = instanceClass.superclass;
    }
    if (instanceClass != null) {
      for (Constructor constructor in instanceClass.constructors) {
        if (constructor.name == name) {
          return constructor;
        }
      }
    }

    /// Performs a similar lookup to [lookupConstructor], but using a slower
    /// implementation.
    Constructor? lookupConstructorWithPatches(Name name, bool isSuper) {
      ClassBuilder? builder = this.origin;

      ClassBuilder? getSuperclass(ClassBuilder builder) {
        // This way of computing the superclass is slower than using the kernel
        // objects directly.
        TypeBuilder? supertype = builder.supertypeBuilder;
        if (supertype is NamedTypeBuilder) {
          TypeDeclarationBuilder? builder = supertype.declaration;
          if (builder is ClassBuilder) return builder;
          if (builder is TypeAliasBuilder) {
            TypeDeclarationBuilder? declarationBuilder =
                builder.unaliasDeclaration(supertype.arguments,
                    isUsedAsClass: true,
                    usedAsClassCharOffset: supertype.charOffset,
                    usedAsClassFileUri: supertype.fileUri);
            if (declarationBuilder is ClassBuilder) return declarationBuilder;
          }
        }
        return null;
      }

      if (isSuper) {
        builder = getSuperclass(builder)?.origin;
      }
      if (builder != null) {
        Class cls = builder.cls;
        for (Constructor constructor in cls.constructors) {
          if (constructor.name == name) return constructor;
        }
      }
      return null;
    }

    return lookupConstructorWithPatches(name, isSuper);
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
      // That should be caught and reported as a compile-time error earlier.
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
          // ignore: unnecessary_null_comparison
          if (substitutionMap != null) {
            // TODO(ahe): Investigate if requiring the caller to use
            // `substituteDeep` from `package:kernel/type_algebra.dart` instead
            // of `substitute` is faster. If so, we can simply this code.
            argument = substitute(argument, substitutionMap);
          }
          directSubstitutionMap[variables[i]] = argument;
        }
        substitutionMap = directSubstitutionMap;
      }
    }

    return substitutionMap;
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is SourceClassBuilder) {
      patch.actualOrigin = this;
      (_patches ??= []).add(patch);

      mergedScope.addAugmentationScope(patch);

      int originLength = typeVariables?.length ?? 0;
      int patchLength = patch.typeVariables?.length ?? 0;
      if (originLength != patchLength) {
        patch.addProblem(messagePatchClassTypeVariablesMismatch,
            patch.charOffset, noLength, context: [
          messagePatchClassOrigin.withLocation(fileUri, charOffset, noLength)
        ]);
      } else if (typeVariables != null) {
        int count = 0;
        for (TypeVariableBuilder t in patch.typeVariables!) {
          typeVariables![count++].applyPatch(t);
        }
      }
    } else {
      libraryBuilder.addProblem(messagePatchDeclarationMismatch,
          patch.charOffset, noLength, patch.fileUri, context: [
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
            Builder? member = superclassHierarchyNode.classBuilder.scope
                .lookupLocalMember(restrictedMemberName, setter: false);
            if (member is MemberBuilder && !member.isAbstract) {
              restrictedMembersInSuperclasses[restrictedMemberName] ??=
                  superclassHierarchyNode.classBuilder;
            }
          }
          Builder? member = superclassHierarchyNode.classBuilder.scope
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
            scope.lookupLocalMember("values", setter: false);
        if (customValuesDeclaration != null &&
            !customValuesDeclaration.isStatic) {
          // Retrieve the earliest declaration for error reporting.
          while (customValuesDeclaration?.next != null) {
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
            scope.lookupLocalMember("values", setter: true);
        if (customValuesDeclaration != null &&
            !customValuesDeclaration.isStatic) {
          // Retrieve the earliest declaration for error reporting.
          while (customValuesDeclaration?.next != null) {
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
              scope.lookupLocalMember(restrictedMemberName, setter: false);
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
      int nameOffset = target.nameOffset;
      int nameLength = target.nameLength;
      if (aliasBuilder != null) {
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
        decl = aliasBuilder.unaliasDeclaration(superClassType.arguments,
            isUsedAsClass: true,
            usedAsClassCharOffset: superClassType.charOffset,
            usedAsClassFileUri: superClassType.fileUri);
      }
      // TODO(eernst): Should gather 'restricted supertype' checks in one place,
      // e.g., dynamic/int/String/Null and more are checked elsewhere.
      if (decl is VoidTypeDeclarationBuilder) {
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
      assert(mixedInTypeBuilder != null,
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
          decl = aliasBuilder.unaliasDeclaration(type.arguments,
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
              interface.cls.enclosingLibrary.importUri.isScheme("dart") &&
              interface.cls.enclosingLibrary.importUri.path == "async") {
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
      InterfaceType? implementedInterface = hierarchy.getTypeAsInstanceOf(
          supertype, requiredInterface.classNode,
          isNonNullableByDefault: libraryBuilder.isNonNullableByDefault);
      if (implementedInterface == null ||
          !typeEnvironment.areMutualSubtypes(
              implementedInterface,
              requiredInterface,
              libraryBuilder.isNonNullableByDefault
                  ? SubtypeCheckMode.withNullabilities
                  : SubtypeCheckMode.ignoringNullabilities)) {
        libraryBuilder.addProblem(
            templateMixinApplicationIncompatibleSupertype.withArguments(
                supertype,
                requiredInterface,
                cls.mixedInType!.asInterfaceType,
                libraryBuilder.isNonNullableByDefault),
            cls.fileOffset,
            noLength,
            cls.fileUri);
      }
    }
  }

  void addProblemForRedirectingFactory(RedirectingFactoryBuilder factory,
      Message message, int charOffset, int length) {
    addProblem(message, charOffset, length);
    String text = libraryBuilder.loader.target.context
        .format(
            message.withLocation(fileUri, charOffset, length), Severity.error)
        .plain;
    factory.body = new RedirectingFactoryBody.error(text);
  }

  void checkRedirectingFactories(TypeEnvironment typeEnvironment) {
    Iterator<SourceFactoryBuilder> iterator = constructorScope.filteredIterator(
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
      TypeVariableBuilder typeVariableBuilder = typeVariables![i];
      int variance = computeTypeVariableBuilderVariance(
          typeVariableBuilder, supertype, libraryBuilder);
      if (!Variance.greaterThanOrEqual(variance, typeVariables![i].variance)) {
        if (typeVariables![i].parameter.isLegacyCovariant) {
          message = templateInvalidTypeVariableInSupertype.withArguments(
              typeVariables![i].name,
              Variance.keywordString(variance),
              supertype.name as String);
        } else {
          message =
              templateInvalidTypeVariableInSupertypeWithVariance.withArguments(
                  Variance.keywordString(typeVariables![i].variance),
                  typeVariables![i].name,
                  Variance.keywordString(variance),
                  supertype.name as String);
        }
        libraryBuilder.addProblem(message, charOffset, noLength, fileUri);
      }
    }
    if (message != null) {
      return new NamedTypeBuilder(
          supertype.name as String, const NullabilityBuilder.omitted(),
          fileUri: fileUri,
          charOffset: charOffset,
          instanceTypeVariableAccess:
              InstanceTypeVariableAccessState.Unexpected)
        ..bind(
            libraryBuilder,
            new InvalidTypeDeclarationBuilder(supertype.name as String,
                message.withLocation(fileUri, charOffset, noLength)));
    }
    return supertype;
  }

  void checkVarianceInField(SourceFieldBuilder fieldBuilder,
      TypeEnvironment typeEnvironment, List<TypeParameter> typeParameters) {
    for (TypeParameter typeParameter in typeParameters) {
      int fieldVariance =
          computeVariance(typeParameter, fieldBuilder.fieldType);
      if (fieldBuilder.isClassInstanceMember) {
        reportVariancePositionIfInvalid(fieldVariance, typeParameter,
            fieldBuilder.fileUri, fieldBuilder.charOffset);
      }
      if (fieldBuilder.isClassInstanceMember &&
          fieldBuilder.isAssignable &&
          !fieldBuilder.isCovariantByDeclaration) {
        fieldVariance = Variance.combine(Variance.contravariant, fieldVariance);
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

    // ignore: unnecessary_null_comparison
    if (functionTypeParameters != null) {
      for (TypeParameter functionParameter in functionTypeParameters) {
        for (TypeParameter typeParameter in typeParameters) {
          int typeVariance = Variance.combine(Variance.invariant,
              computeVariance(typeParameter, functionParameter.bound));
          reportVariancePositionIfInvalid(typeVariance, typeParameter, fileUri,
              functionParameter.fileOffset);
        }
      }
    }
    // ignore: unnecessary_null_comparison
    if (positionalParameters != null) {
      for (VariableDeclaration formal in positionalParameters) {
        if (!formal.isCovariantByDeclaration) {
          for (TypeParameter typeParameter in typeParameters) {
            int formalVariance = Variance.combine(Variance.contravariant,
                computeVariance(typeParameter, formal.type));
            reportVariancePositionIfInvalid(
                formalVariance, typeParameter, fileUri, formal.fileOffset);
          }
        }
      }
    }
    // ignore: unnecessary_null_comparison
    if (namedParameters != null) {
      for (VariableDeclaration named in namedParameters) {
        for (TypeParameter typeParameter in typeParameters) {
          int namedVariance = Variance.combine(Variance.contravariant,
              computeVariance(typeParameter, named.type));
          reportVariancePositionIfInvalid(
              namedVariance, typeParameter, fileUri, named.fileOffset);
        }
      }
    }
    // ignore: unnecessary_null_comparison
    if (returnType != null) {
      for (TypeParameter typeParameter in typeParameters) {
        int returnTypeVariance = computeVariance(typeParameter, returnType);
        reportVariancePositionIfInvalid(returnTypeVariance, typeParameter,
            fileUri, procedure.function.fileOffset,
            isReturnType: true);
      }
    }
  }

  void reportVariancePositionIfInvalid(
      int variance, TypeParameter typeParameter, Uri fileUri, int fileOffset,
      {bool isReturnType = false}) {
    SourceLibraryBuilder library = this.libraryBuilder;
    if (!typeParameter.isLegacyCovariant &&
        !Variance.greaterThanOrEqual(variance, typeParameter.variance)) {
      Message message;
      if (isReturnType) {
        message = templateInvalidTypeVariableVariancePositionInReturnType
            .withArguments(Variance.keywordString(typeParameter.variance),
                typeParameter.name!, Variance.keywordString(variance));
      } else {
        message = templateInvalidTypeVariableVariancePosition.withArguments(
            Variance.keywordString(typeParameter.variance),
            typeParameter.name!,
            Variance.keywordString(variance));
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
    constructorBuilder.next = constructorScope.lookupLocalMember(name);
    constructorScope.addLocalMember(name, constructorBuilder);
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
    // TODO(ahe): restore file-offset once we track both origin and patch file
    // URIs. See https://github.com/dart-lang/sdk/issues/31579
    if (isPatch) {
      cls.annotations.forEach((m) => m.fileOffset = origin.cls.fileOffset);
    }

    int count = 0;

    void buildMembers(Builder builder) {
      if (builder.parent != this) {
        return;
      }
      if (builder is SourceMemberBuilder) {
        count += builder.buildBodyNodes((Member member, BuiltMemberKind kind) {
          _addMemberToClass(builder, member, kind);
        });
      }
    }

    scope
        .filteredIterator(
            parent: this, includeDuplicates: true, includeAugmentations: true)
        .forEach(buildMembers);
    constructorScope
        .filteredIterator(
            parent: this, includeDuplicates: true, includeAugmentations: true)
        .forEach(buildMembers);
    return count;
  }

  void _addMemberToClass(SourceMemberBuilder memberBuilder, Member member,
      BuiltMemberKind memberKind) {
    member.parent = cls;
    if (!memberBuilder.isPatch &&
        !memberBuilder.isDuplicate &&
        !memberBuilder.isConflictingSetter) {
      if (memberBuilder.isConflictingAugmentationMember) {
        if (member is Field && member.isStatic ||
            member is Procedure && member.isStatic) {
          member.name = new Name(
              '${member.name}#${memberBuilder.libraryBuilder.patchIndex}',
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
      } else if (member is RedirectingFactory) {
        cls.addRedirectingFactory(member);
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
            namedBuilder.arguments,
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
              namedBuilder.arguments,
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
            namedBuilder.arguments,
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

  /// If any private field names in this library are unpromotable due to fields
  /// in this class, adds them to [unpromotablePrivateFieldNames].
  void addUnpromotablePrivateFieldNames(
      Set<String> unpromotablePrivateFieldNames) {
    for (Field field in cls.fields) {
      // An instance field is unpromotable (and makes other fields with the same
      // name unpromotable) if it's not final.
      if (field.isInstanceMember &&
          !field.isFinal &&
          _isPrivateNameInThisLibrary(field.name)) {
        unpromotablePrivateFieldNames.add(field.name.text);
      }
    }
    for (Procedure procedure in cls.procedures) {
      // An instance getter makes fields with the same name unpromotable if it's
      // concrete.  Also, an abstract instance setter that's desugared from an
      // abstract non-final field makes fields with the same name unpromotable.
      if (procedure.isInstanceMember &&
          _isPrivateNameInThisLibrary(procedure.name)) {
        if (procedure.isGetter && !procedure.isAbstract) {
          ProcedureStubKind procedureStubKind = procedure.stubKind;
          if (procedureStubKind == ProcedureStubKind.Regular ||
              procedureStubKind == ProcedureStubKind.NoSuchMethodForwarder) {
            unpromotablePrivateFieldNames.add(procedure.name.text);
          }
        } else if (procedure.isSetter && procedure.isAbstractFieldAccessor) {
          unpromotablePrivateFieldNames.add(procedure.name.text);
        }
      }
    }
  }

  bool _isPrivateNameInThisLibrary(Name name) =>
      name.isPrivate && name.library == libraryBuilder.library;

  void _addRedirectingConstructor(
      SourceFactoryBuilder constructorBuilder,
      SourceLibraryBuilder library,
      Reference? fieldReference,
      Reference? getterReference) {
    // Add a new synthetic field to this class for representing factory
    // constructors. This is used to support resolving such constructors in
    // source code.
    //
    // The synthetic field looks like this:
    //
    //     final _redirecting# = [c1, ..., cn];
    //
    // Where each c1 ... cn are an instance of [StaticGet] whose target is
    // [constructor.target].
    //
    // TODO(ahe): Add a kernel node to represent redirecting factory bodies.
    _RedirectingConstructorsFieldBuilder? constructorsField =
        origin.scope.lookupLocalMember(redirectingName, setter: false)
            as _RedirectingConstructorsFieldBuilder?;
    if (constructorsField == null) {
      ListLiteral literal = new ListLiteral(<Expression>[]);
      Name name = new Name(redirectingName, library.library);
      Field field = new Field.immutable(name,
          isStatic: true,
          isFinal: true,
          initializer: literal,
          fileUri: cls.fileUri,
          fieldReference: fieldReference,
          getterReference: getterReference)
        ..fileOffset = cls.fileOffset;
      cls.addField(field);
      constructorsField = new _RedirectingConstructorsFieldBuilder(field, this);
      origin.scope
          .addLocalMember(redirectingName, constructorsField, setter: false);
    }
    Field field = constructorsField.field;
    ListLiteral literal = field.initializer as ListLiteral;
    literal.expressions.add(
        new ConstructorTearOff(constructorBuilder.member)..parent = literal);
  }

  int resolveConstructors(SourceLibraryBuilder library) {
    if (constructorReferences == null) return 0;
    for (ConstructorReferenceBuilder ref in constructorReferences!) {
      ref.resolveIn(scope, library);
    }
    int count = constructorReferences!.length;
    if (count != 0) {
      Iterator<MemberBuilder> iterator = constructorScope.filteredIterator(
          parent: this, includeDuplicates: true, includeAugmentations: true);
      while (iterator.moveNext()) {
        MemberBuilder declaration = iterator.current;
        if (declaration.parent?.origin != origin) {
          unexpected("$fileUri", "${declaration.parent!.fileUri}", charOffset,
              fileUri);
        }
        if (declaration is RedirectingFactoryBuilder) {
          // Compute the immediate redirection target, not the effective.

          ConstructorReferenceBuilder redirectionTarget =
              declaration.redirectionTarget;
          List<TypeBuilder>? typeArguments = redirectionTarget.typeArguments;
          Builder? target = redirectionTarget.target;
          if (typeArguments != null && target is MemberBuilder) {
            Object? redirectionTargetName = redirectionTarget.name;
            if (redirectionTargetName is String) {
              // Do nothing. This is the case of an identifier followed by
              // type arguments, such as the following:
              //   B<T>
              //   B<T>.named
            } else if (redirectionTargetName is QualifiedName) {
              if (target.name.isEmpty) {
                // Do nothing. This is the case of a qualified
                // non-constructor prefix (for example, with a library
                // qualifier) followed by type arguments, such as the
                // following:
                //   lib.B<T>
              } else if (target.name != redirectionTargetName.suffix.lexeme) {
                // Do nothing. This is the case of a qualified
                // non-constructor prefix followed by type arguments followed
                // by a constructor name, such as the following:
                //   lib.B<T>.named
              } else {
                // TODO(cstefantsova,johnniwinther): Handle this in case in
                // ConstructorReferenceBuilder.resolveIn and unify with other
                // cases of handling of type arguments after constructor
                // names.
                addProblem(
                    messageConstructorWithTypeArguments,
                    redirectionTargetName.charOffset,
                    redirectionTargetName.name.length);
              }
            }
          }

          // ignore: unnecessary_null_comparison
          if (redirectionTarget != null) {
            Builder? targetBuilder = redirectionTarget.target;
            if (declaration.next == null) {
              // Only the first one (that is, the last on in the linked list)
              // is actually in the kernel tree. This call creates a StaticGet
              // to [declaration.target] in a field `_redirecting#` which is
              // only legal to do to things in the kernel tree.
              Reference? fieldReference;
              Reference? getterReference;
              if (referencesFromIndexed != null) {
                Name name =
                    new Name(redirectingName, referencesFromIndexed!.library);
                fieldReference =
                    referencesFromIndexed!.lookupFieldReference(name);
                getterReference =
                    referencesFromIndexed!.lookupGetterReference(name);
              }
              _addRedirectingConstructor(
                  declaration, library, fieldReference, getterReference);
            }
            Member? targetNode;
            if (targetBuilder is FunctionBuilder) {
              targetNode = targetBuilder.member;
            } else if (targetBuilder is DillMemberBuilder) {
              targetNode = targetBuilder.member;
            } else if (targetBuilder is AmbiguousBuilder) {
              addProblemForRedirectingFactory(
                  declaration,
                  templateDuplicatedDeclarationUse
                      .withArguments(redirectionTarget.fullNameForErrors),
                  redirectionTarget.charOffset,
                  noLength);
            } else {
              addProblemForRedirectingFactory(
                  declaration,
                  templateRedirectionTargetNotFound
                      .withArguments(redirectionTarget.fullNameForErrors),
                  redirectionTarget.charOffset,
                  noLength);
            }
            if (targetNode != null &&
                targetNode is Constructor &&
                targetNode.enclosingClass.isAbstract) {
              addProblemForRedirectingFactory(
                  declaration,
                  templateAbstractRedirectedClassInstantiation
                      .withArguments(redirectionTarget.fullNameForErrors),
                  redirectionTarget.charOffset,
                  noLength);
              targetNode = null;
            }
            if (targetNode != null &&
                targetNode is Constructor &&
                targetNode.enclosingClass.isEnum) {
              addProblemForRedirectingFactory(
                  declaration,
                  messageEnumFactoryRedirectsToConstructor,
                  redirectionTarget.charOffset,
                  noLength);
              targetNode = null;
            }
            if (targetNode != null) {
              List<DartType> typeArguments = declaration.typeArguments ??
                  new List<DartType>.filled(
                      targetNode.enclosingClass!.typeParameters.length,
                      const UnknownType());
              declaration.setRedirectingFactoryBody(targetNode, typeArguments);
            }
          }
        }
      }
    }
    return count;
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
      {required bool isInterfaceCheck,
      required bool declaredNeedsLegacyErasure}) {
    // ignore: unnecessary_null_comparison
    assert(isInterfaceCheck != null);
    // ignore: unnecessary_null_comparison
    assert(declaredNeedsLegacyErasure != null);
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
          bool seenCovariant = checkMethodOverride(
              types,
              declaredMember,
              interfaceMember,
              interfaceMemberOrigin,
              isInterfaceCheck,
              declaredNeedsLegacyErasure);
          if (seenCovariant) {
            _handleSeenCovariant(
                memberHierarchy, interfaceMember, isSetter, callback);
          }
        } else if (declaredMember.kind == ProcedureKind.Getter) {
          checkGetterOverride(
              types,
              declaredMember,
              interfaceMember,
              interfaceMemberOrigin,
              isInterfaceCheck,
              declaredNeedsLegacyErasure);
        } else if (declaredMember.kind == ProcedureKind.Setter) {
          bool seenCovariant = checkSetterOverride(
              types,
              declaredMember,
              interfaceMember,
              interfaceMemberOrigin,
              isInterfaceCheck,
              declaredNeedsLegacyErasure);
          if (seenCovariant) {
            _handleSeenCovariant(
                memberHierarchy, interfaceMember, isSetter, callback);
          }
        } else {
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
        checkGetterOverride(
            types,
            declaredMember,
            interfaceMember,
            interfaceMemberOrigin,
            isInterfaceCheck,
            declaredNeedsLegacyErasure);
      }
      if (declaredMemberHasSetter && interfaceMemberHasSetter) {
        bool seenCovariant = checkSetterOverride(
            types,
            declaredMember,
            interfaceMember,
            interfaceMemberOrigin,
            isInterfaceCheck,
            declaredNeedsLegacyErasure);
        if (seenCovariant) {
          _handleSeenCovariant(
              memberHierarchy, interfaceMember, isSetter, callback);
        }
      }
    }
    // TODO(ahe): Handle other cases: accessors, operators, and fields.
  }

  void checkGetterSetter(Types types, Member getter, Member setter) {
    if (getter == setter) {
      return;
    }
    if (cls != getter.enclosingClass &&
        getter.enclosingClass == setter.enclosingClass) {
      return;
    }

    DartType getterType = getter.getterType;
    if (getter.enclosingClass!.typeParameters.isNotEmpty) {
      getterType = Substitution.fromPairs(
              getter.enclosingClass!.typeParameters,
              types.hierarchy.getTypeArgumentsAsInstanceOf(
                  thisType, getter.enclosingClass!)!)
          .substituteType(getterType);
    }

    DartType setterType = setter.setterType;
    if (setter.enclosingClass!.typeParameters.isNotEmpty) {
      setterType = Substitution.fromPairs(
              setter.enclosingClass!.typeParameters,
              types.hierarchy.getTypeArgumentsAsInstanceOf(
                  thisType, setter.enclosingClass!)!)
          .substituteType(setterType);
    }

    if (getterType is InvalidType || setterType is InvalidType) {
      // Don't report a problem as something else is wrong that has already
      // been reported.
    } else {
      bool isValid = types.isSubtypeOf(
          getterType,
          setterType,
          libraryBuilder.isNonNullableByDefault
              ? SubtypeCheckMode.withNullabilities
              : SubtypeCheckMode.ignoringNullabilities);
      if (!isValid && !libraryBuilder.isNonNullableByDefault) {
        // Allow assignability in legacy libraries.
        isValid = types.isSubtypeOf(
            setterType, getterType, SubtypeCheckMode.ignoringNullabilities);
      }
      if (!isValid) {
        Member getterOrigin = getter.memberSignatureOrigin ?? getter;
        Member setterOrigin = setter.memberSignatureOrigin ?? setter;
        String getterMemberName = '${getterOrigin.enclosingClass!.name}'
            '.${getterOrigin.name.text}';
        String setterMemberName = '${setterOrigin.enclosingClass!.name}'
            '.${setterOrigin.name.text}';
        if (getterOrigin.enclosingClass == cls &&
            setterOrigin.enclosingClass == cls) {
          Template<Message Function(DartType, String, DartType, String, bool)>
              template = libraryBuilder.isNonNullableByDefault
                  ? templateInvalidGetterSetterType
                  : templateInvalidGetterSetterTypeLegacy;
          libraryBuilder.addProblem(
              template.withArguments(getterType, getterMemberName, setterType,
                  setterMemberName, libraryBuilder.isNonNullableByDefault),
              getterOrigin.fileOffset,
              getterOrigin.name.text.length,
              getterOrigin.fileUri,
              context: [
                templateInvalidGetterSetterTypeSetterContext
                    .withArguments(setterMemberName)
                    .withLocation(setterOrigin.fileUri, setterOrigin.fileOffset,
                        setterOrigin.name.text.length)
              ]);
        } else if (getterOrigin.enclosingClass == cls) {
          Template<Message Function(DartType, String, DartType, String, bool)>
              template = libraryBuilder.isNonNullableByDefault
                  ? templateInvalidGetterSetterTypeSetterInheritedGetter
                  : templateInvalidGetterSetterTypeSetterInheritedGetterLegacy;
          if (getterOrigin is Field) {
            template = libraryBuilder.isNonNullableByDefault
                ? templateInvalidGetterSetterTypeSetterInheritedField
                : templateInvalidGetterSetterTypeSetterInheritedFieldLegacy;
          }
          libraryBuilder.addProblem(
              template.withArguments(getterType, getterMemberName, setterType,
                  setterMemberName, libraryBuilder.isNonNullableByDefault),
              getterOrigin.fileOffset,
              getterOrigin.name.text.length,
              getterOrigin.fileUri,
              context: [
                templateInvalidGetterSetterTypeSetterContext
                    .withArguments(setterMemberName)
                    .withLocation(setterOrigin.fileUri, setterOrigin.fileOffset,
                        setterOrigin.name.text.length)
              ]);
        } else if (setterOrigin.enclosingClass == cls) {
          Template<Message Function(DartType, String, DartType, String, bool)>
              template = libraryBuilder.isNonNullableByDefault
                  ? templateInvalidGetterSetterTypeGetterInherited
                  : templateInvalidGetterSetterTypeGetterInheritedLegacy;
          Template<Message Function(String)> context =
              templateInvalidGetterSetterTypeGetterContext;
          if (getterOrigin is Field) {
            template = libraryBuilder.isNonNullableByDefault
                ? templateInvalidGetterSetterTypeFieldInherited
                : templateInvalidGetterSetterTypeFieldInheritedLegacy;
            context = templateInvalidGetterSetterTypeFieldContext;
          }
          libraryBuilder.addProblem(
              template.withArguments(getterType, getterMemberName, setterType,
                  setterMemberName, libraryBuilder.isNonNullableByDefault),
              setterOrigin.fileOffset,
              setterOrigin.name.text.length,
              setterOrigin.fileUri,
              context: [
                context.withArguments(getterMemberName).withLocation(
                    getterOrigin.fileUri,
                    getterOrigin.fileOffset,
                    getterOrigin.name.text.length)
              ]);
        } else {
          Template<Message Function(DartType, String, DartType, String, bool)>
              template = libraryBuilder.isNonNullableByDefault
                  ? templateInvalidGetterSetterTypeBothInheritedGetter
                  : templateInvalidGetterSetterTypeBothInheritedGetterLegacy;
          Template<Message Function(String)> context =
              templateInvalidGetterSetterTypeGetterContext;
          if (getterOrigin is Field) {
            template = libraryBuilder.isNonNullableByDefault
                ? templateInvalidGetterSetterTypeBothInheritedField
                : templateInvalidGetterSetterTypeBothInheritedFieldLegacy;
            context = templateInvalidGetterSetterTypeFieldContext;
          }
          libraryBuilder.addProblem(
              template.withArguments(getterType, getterMemberName, setterType,
                  setterMemberName, libraryBuilder.isNonNullableByDefault),
              charOffset,
              noLength,
              fileUri,
              context: [
                context.withArguments(getterMemberName).withLocation(
                    getterOrigin.fileUri,
                    getterOrigin.fileOffset,
                    getterOrigin.name.text.length),
                templateInvalidGetterSetterTypeSetterContext
                    .withArguments(setterMemberName)
                    .withLocation(setterOrigin.fileUri, setterOrigin.fileOffset,
                        setterOrigin.name.text.length)
              ]);
        }
      }
    }
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
      bool isInterfaceCheck,
      bool declaredNeedsLegacyErasure) {
    Substitution? interfaceSubstitution;
    if (interfaceMember.enclosingClass!.typeParameters.isNotEmpty) {
      Class enclosingClass = interfaceMember.enclosingClass!;
      interfaceSubstitution = Substitution.fromPairs(
          enclosingClass.typeParameters,
          types.hierarchy
              .getTypeArgumentsAsInstanceOf(thisType, enclosingClass)!);
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
      Map<TypeParameter, DartType> substitutionMap =
          <TypeParameter, DartType>{};

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
      for (int i = 0; i < declaredFunction!.typeParameters.length; ++i) {
        substitutionMap[interfaceFunction.typeParameters[i]] =
            new TypeParameterType.forAlphaRenaming(
                interfaceTypeParameters[i], declaredFunction.typeParameters[i]);
      }
      Substitution substitution = Substitution.fromMap(substitutionMap);
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
          if (!libraryBuilder.isNonNullableByDefault) {
            computedBound = legacyErasure(computedBound);
          }
          if (declaredNeedsLegacyErasure) {
            declaredBound = legacyErasure(declaredBound);
          }
          if (!types
              .performNullabilityAwareMutualSubtypesCheck(
                  declaredBound, computedBound)
              .isSubtypeWhenUsingNullabilities()) {
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
                        "${interfaceMemberOrigin.name.text}",
                    libraryBuilder.isNonNullableByDefault),
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
          types.hierarchy
              .getTypeArgumentsAsInstanceOf(thisType, enclosingClass)!);
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
      bool declaredNeedsLegacyErasure,
      {bool asIfDeclaredParameter = false}) {
    if (interfaceSubstitution != null) {
      interfaceType = interfaceSubstitution.substituteType(interfaceType);
    }
    if (declaredSubstitution != null) {
      declaredType = declaredSubstitution.substituteType(declaredType);
    }
    if (declaredNeedsLegacyErasure) {
      declaredType = legacyErasure(declaredType);
    }

    if (!declaredMember.isNonNullableByDefault &&
        interfaceMember.isNonNullableByDefault) {
      interfaceType = legacyErasure(interfaceType);
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
      bool isErrorInNnbdOptedOutMode = !types.isSubtypeOf(
              subtype, supertype, SubtypeCheckMode.ignoringNullabilities) &&
          (!isCovariantByDeclaration ||
              !types.isSubtypeOf(
                  supertype, subtype, SubtypeCheckMode.ignoringNullabilities));
      if (isErrorInNnbdOptedOutMode || libraryBuilder.isNonNullableByDefault) {
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
                interfaceMemberName,
                libraryBuilder.isNonNullableByDefault);
          } else {
            message = templateOverrideTypeMismatchReturnType.withArguments(
                declaredMemberName,
                declaredType,
                interfaceType,
                interfaceMemberName,
                libraryBuilder.isNonNullableByDefault);
          }
          fileOffset = declaredMember.fileOffset;
        } else {
          message = templateOverrideTypeMismatchParameter.withArguments(
              declaredParameter.name!,
              declaredMemberName,
              declaredType,
              interfaceType,
              interfaceMemberName,
              libraryBuilder.isNonNullableByDefault);
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
      bool isInterfaceCheck,
      bool declaredNeedsLegacyErasure) {
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
        isInterfaceCheck,
        declaredNeedsLegacyErasure);

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
        isInterfaceCheck,
        declaredNeedsLegacyErasure);
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
          isInterfaceCheck,
          declaredNeedsLegacyErasure);
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
          isInterfaceCheck,
          declaredNeedsLegacyErasure);
      if (declaredMember.isNonNullableByDefault &&
          !declaredNeedsLegacyErasure &&
          declaredParameter.isRequired &&
          interfaceMember.isNonNullableByDefault &&
          !interfaceNamedParameters.current.isRequired) {
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
      bool isInterfaceCheck,
      bool declaredNeedsLegacyErasure) {
    Substitution? interfaceSubstitution = _computeInterfaceSubstitution(
        types,
        declaredMember,
        interfaceMember,
        interfaceMemberOrigin,
        /* declaredFunction = */ null,
        /* interfaceFunction = */ null,
        isInterfaceCheck,
        declaredNeedsLegacyErasure);
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
        /* isCovariantByDeclaration = */ false,
        /* declaredParameter = */ null,
        isInterfaceCheck,
        declaredNeedsLegacyErasure);
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
      bool isInterfaceCheck,
      bool declaredNeedsLegacyErasure) {
    Substitution? interfaceSubstitution = _computeInterfaceSubstitution(
        types,
        declaredMember,
        interfaceMember,
        interfaceMemberOrigin,
        /* declaredFunction = */ null,
        /* interfaceFunction = */ null,
        isInterfaceCheck,
        declaredNeedsLegacyErasure);
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
        declaredNeedsLegacyErasure,
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
int? getOverlookedOverrideProblemChoice(ClassBuilder classBuilder) {
  String uri = '${classBuilder.libraryBuilder.importUri}';
  if (uri == 'dart:js' && classBuilder.fileUri.pathSegments.last == 'js.dart') {
    return 0;
  } else if (uri == 'dart:_interceptors' &&
      classBuilder.fileUri.pathSegments.last == 'js_number.dart') {
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
      classDeclaration._patches;
}

class _RedirectingConstructorsFieldBuilder extends DillFieldBuilder
    with SourceMemberBuilderMixin {
  _RedirectingConstructorsFieldBuilder(Field field, SourceClassBuilder parent)
      : super(field, parent);

  @override
  SourceLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as SourceLibraryBuilder;

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    // Do nothing.
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(
      SourceLibraryBuilder library, TypeEnvironment typeEnvironment) {}
}
