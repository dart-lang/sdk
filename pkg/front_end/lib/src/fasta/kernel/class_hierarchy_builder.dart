// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart'
    show
        Class,
        DartType,
        InterfaceType,
        TypeParameter,
        Library,
        Member,
        Name,
        Procedure,
        ProcedureKind,
        Supertype;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/type_algebra.dart' show Substitution;

import '../loader.dart' show Loader;

import '../messages.dart'
    show
        LocatedMessage,
        Message,
        messageDeclaredMemberConflictsWithInheritedMember,
        messageDeclaredMemberConflictsWithInheritedMemberCause,
        messageInheritedMembersConflict,
        messageInheritedMembersConflictCause1,
        messageInheritedMembersConflictCause2,
        messageStaticAndInstanceConflict,
        messageStaticAndInstanceConflictCause,
        templateDuplicatedDeclaration,
        templateDuplicatedDeclarationCause,
        templateMissingImplementationCause,
        templateMissingImplementationNotAbstract;

import '../names.dart' show noSuchMethodName;

import '../scope.dart' show Scope;

import '../type_inference/standard_bounds.dart' show StandardBounds;

import '../type_inference/type_constraint_gatherer.dart'
    show TypeConstraintGatherer;

import '../type_inference/type_inferrer.dart' show MixinInferrer;

import '../type_inference/type_schema.dart' show UnknownType;

import '../type_inference/type_schema_environment.dart' show TypeConstraint;

import 'kernel_builder.dart'
    show
        Declaration,
        KernelClassBuilder,
        KernelNamedTypeBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        TypeBuilder,
        TypeVariableBuilder;

import 'types.dart' show Types;

int compareDeclarations(Declaration a, Declaration b) {
  return ClassHierarchy.compareMembers(a.target, b.target);
}

ProcedureKind memberKind(Member member) {
  return member is Procedure ? member.kind : null;
}

bool isNameVisibleIn(
    Name name, LibraryBuilder<KernelTypeBuilder, Library> library) {
  return !name.isPrivate || name.library == library.target;
}

/// Returns true if [a] is a class member conflict with [b].  [a] is assumed to
/// be declared in the class, [b] is assumed to be inherited.
///
/// See the section named "Class Member Conflicts" in [Dart Programming
/// Language Specification](
/// ../../../../../../docs/language/dartLangSpec.tex#classMemberConflicts).
bool isInheritanceConflict(Declaration a, Declaration b) {
  if (a.isStatic) return true;
  if (memberKind(a.target) == memberKind(b.target)) return false;
  if (a.isField) return !(b.isField || b.isGetter || b.isSetter);
  if (b.isField) return !(a.isField || a.isGetter || a.isSetter);
  if (a.isSetter) return !(b.isGetter || b.isSetter);
  if (b.isSetter) return !(a.isGetter || a.isSetter);
  return true;
}

bool impliesSetter(Declaration declaration) {
  return declaration.isField && !(declaration.isFinal || declaration.isConst);
}

class ClassHierarchyBuilder {
  final Map<Class, ClassHierarchyNode> nodes = <Class, ClassHierarchyNode>{};

  final KernelClassBuilder objectClass;

  final Loader<Library> loader;

  final Class objectKernelClass;

  final Class futureKernelClass;

  final Class futureOrKernelClass;

  final Class functionKernelClass;

  final Class nullKernelClass;

  // TODO(ahe): Remove this.
  final CoreTypes coreTypes;

  Types types;

  ClassHierarchyBuilder(this.objectClass, this.loader, this.coreTypes)
      : objectKernelClass = objectClass.target,
        futureKernelClass = coreTypes.futureClass,
        futureOrKernelClass = coreTypes.futureOrClass,
        functionKernelClass = coreTypes.functionClass,
        nullKernelClass = coreTypes.nullClass {
    types = new Types(this);
  }

  ClassHierarchyNode getNodeFromClass(KernelClassBuilder cls) {
    return nodes[cls.target] ??=
        new ClassHierarchyNodeBuilder(this, cls).build();
  }

  ClassHierarchyNode getNodeFromType(KernelTypeBuilder type) {
    Declaration declaration = type.declaration;
    return declaration is KernelClassBuilder
        ? getNodeFromClass(declaration)
        : null;
  }

  ClassHierarchyNode getNodeFromKernelClass(Class cls) {
    return nodes[cls] ??
        getNodeFromClass(loader.computeClassBuilderFromTargetClass(cls));
  }

  KernelTypeBuilder asSupertypeOf(Class cls, Class supertype) {
    ClassHierarchyNode clsNode = getNodeFromKernelClass(cls);
    if (cls == supertype) {
      return new KernelNamedTypeBuilder(clsNode.cls.name, null)
        ..bind(clsNode.cls);
    }
    ClassHierarchyNode supertypeNode = getNodeFromKernelClass(supertype);
    List<KernelTypeBuilder> supertypes = clsNode.superclasses;
    int depth = supertypeNode.depth;
    Declaration supertypeDeclaration = supertypeNode.cls;
    if (depth < supertypes.length) {
      KernelTypeBuilder asSupertypeOf = supertypes[depth];
      if (asSupertypeOf.declaration == supertypeDeclaration)
        return asSupertypeOf;
    }
    supertypes = clsNode.interfaces;
    for (int i = 0; i < supertypes.length; i++) {
      KernelTypeBuilder type = supertypes[i];
      if (type.declaration == supertypeDeclaration) return type;
    }
    return null;
  }

  InterfaceType getKernelTypeAsInstanceOf(
      InterfaceType type, Class superclass) {
    Class kernelClass = type.classNode;
    if (kernelClass == superclass) return type;
    if (kernelClass == nullKernelClass) {
      if (superclass.typeParameters.isEmpty) {
        return superclass.rawType;
      } else {
        // This is a safe fall-back for dealing with `Null`. It will likely be
        // faster to check for `Null` before calling this method.
        return new InterfaceType(
            superclass,
            new List<DartType>.filled(
                superclass.typeParameters.length, nullKernelClass.rawType));
      }
    }
    KernelNamedTypeBuilder supertype = asSupertypeOf(kernelClass, superclass);
    if (supertype == null) return null;
    if (supertype.arguments == null) return superclass.rawType;
    return Substitution.fromInterfaceType(type)
        .substituteType(supertype.build(null));
  }

  InterfaceType getKernelLegacyLeastUpperBound(
      InterfaceType type1, InterfaceType type2) {
    if (type1 == type2) return type1;
    ClassHierarchyNode node1 = getNodeFromKernelClass(type1.classNode);
    ClassHierarchyNode node2 = getNodeFromKernelClass(type2.classNode);
    Set<ClassHierarchyNode> nodes1 = node1.computeAllSuperNodes(this).toSet();
    List<ClassHierarchyNode> nodes2 = node2.computeAllSuperNodes(this);
    List<ClassHierarchyNode> common = <ClassHierarchyNode>[];

    for (int i = 0; i < nodes2.length; i++) {
      ClassHierarchyNode node = nodes2[i];
      if (node == null) continue;
      if (nodes1.contains(node)) {
        DartType candidate1 = getKernelTypeAsInstanceOf(type1, node.cls.target);
        DartType candidate2 = getKernelTypeAsInstanceOf(type2, node.cls.target);
        if (candidate1 == candidate2) {
          common.add(node);
        }
      }
    }

    if (common.length == 1) return objectKernelClass.rawType;
    common.sort(ClassHierarchyNode.compareMaxInheritancePath);

    for (int i = 0; i < common.length - 1; i++) {
      ClassHierarchyNode node = common[i];
      if (node.maxInheritancePath != common[i + 1].maxInheritancePath) {
        return getKernelTypeAsInstanceOf(type1, node.cls.target);
      } else {
        do {
          i++;
        } while (node.maxInheritancePath == common[i + 1].maxInheritancePath);
      }
    }
    return objectKernelClass.rawType;
  }

  static ClassHierarchyBuilder build(
      KernelClassBuilder objectClass,
      List<KernelClassBuilder> classes,
      Loader<Object> loader,
      CoreTypes coreTypes) {
    ClassHierarchyBuilder hierarchy =
        new ClassHierarchyBuilder(objectClass, loader, coreTypes);
    for (int i = 0; i < classes.length; i++) {
      KernelClassBuilder cls = classes[i];
      hierarchy.nodes[cls.target] =
          new ClassHierarchyNodeBuilder(hierarchy, cls).build();
    }
    return hierarchy;
  }
}

class ClassHierarchyNodeBuilder {
  final ClassHierarchyBuilder hierarchy;

  final KernelClassBuilder cls;

  bool hasNoSuchMethod = false;

  List<Declaration> abstractMembers = null;

  ClassHierarchyNodeBuilder(this.hierarchy, this.cls);

  KernelClassBuilder get objectClass => hierarchy.objectClass;

  /// When merging `aList` and `bList`, [a] (from `aList`) and [b] (from
  /// `bList`) each have the same name.
  ///
  /// If [mergeKind] is `MergeKind.superclass`, [a] should override [b].
  ///
  /// If [mergeKind] is `MergeKind.interfaces`, we need to record them and
  /// solve the conflict later.
  ///
  /// If [mergeKind] is `MergeKind.supertypes`, [a] should implement [b], and
  /// [b] is implicitly abstract.
  Declaration handleMergeConflict(KernelClassBuilder cls, Declaration a,
      Declaration b, MergeKind mergeKind) {
    if (a == b) return a;
    if (a.next != null || b.next != null) {
      // Don't check overrides involving duplicated members.
      return a;
    }
    if (isInheritanceConflict(a, b)) {
      reportInheritanceConflict(cls, a, b);
    }
    Declaration result = a;
    if (mergeKind == MergeKind.accessors) {
    } else if (mergeKind == MergeKind.interfaces) {
      // TODO(ahe): Combine the signatures of a and b.  See the section named
      // "Combined Member Signatures" in [Dart Programming Language
      // Specification](
      // ../../../../../../docs/language/dartLangSpec.tex#combinedMemberSignatures).
    } else if (a.target.isAbstract) {
      if (mergeKind == MergeKind.superclass && !b.target.isAbstract) {
        // An abstract method doesn't override an implemention inherited from a
        // superclass.
        result = b;
      } else {
        (abstractMembers ??= <Declaration>[]).add(a);
      }
    }

    if (mergeKind == MergeKind.superclass &&
        result.fullNameForErrors == noSuchMethodName.name &&
        result.parent != objectClass) {
      hasNoSuchMethod = true;
    }

    return result;
  }

  void reportInheritanceConflict(
      KernelClassBuilder cls, Declaration a, Declaration b) {
    String name = a.fullNameForErrors;
    if (a.parent != b.parent) {
      if (a.parent == cls) {
        cls.addProblem(messageDeclaredMemberConflictsWithInheritedMember,
            a.charOffset, name.length,
            context: <LocatedMessage>[
              messageDeclaredMemberConflictsWithInheritedMemberCause
                  .withLocation(b.fileUri, b.charOffset, name.length)
            ]);
      } else {
        cls.addProblem(messageInheritedMembersConflict, cls.charOffset,
            cls.fullNameForErrors.length,
            context: inheritedConflictContext(a, b));
      }
    } else if (a.isStatic != b.isStatic) {
      Declaration staticMember;
      Declaration instanceMember;
      if (a.isStatic) {
        staticMember = a;
        instanceMember = b;
      } else {
        staticMember = b;
        instanceMember = a;
      }
      cls.library.addProblem(messageStaticAndInstanceConflict,
          staticMember.charOffset, name.length, staticMember.fileUri,
          context: <LocatedMessage>[
            messageStaticAndInstanceConflictCause.withLocation(
                instanceMember.fileUri, instanceMember.charOffset, name.length)
          ]);
    } else {
      // This message can be reported twice (when merging localMembers with
      // classSetters, or localSetters with classMembers). By ensuring that
      // we always report the one with higher charOffset as the duplicate,
      // the message duplication logic ensures that we only report this
      // problem once.
      Declaration existing;
      Declaration duplicate;
      assert(a.fileUri == b.fileUri);
      if (a.charOffset < b.charOffset) {
        existing = a;
        duplicate = b;
      } else {
        existing = b;
        duplicate = a;
      }
      cls.library.addProblem(templateDuplicatedDeclaration.withArguments(name),
          duplicate.charOffset, name.length, duplicate.fileUri,
          context: <LocatedMessage>[
            templateDuplicatedDeclarationCause.withArguments(name).withLocation(
                existing.fileUri, existing.charOffset, name.length)
          ]);
    }
  }

  /// When merging `aList` and `bList`, [member] was only found in `aList`.
  ///
  /// If [mergeKind] is `MergeKind.superclass` [member] is declared in current
  /// class, and isn't overriding a method from the superclass.
  ///
  /// If [mergeKind] is `MergeKind.interfaces`, [member] is ignored for now.
  ///
  /// If [mergeKind] is `MergeKind.supertypes`, [member] isn't
  /// implementing/overriding anything.
  void handleOnlyA(Declaration member, MergeKind mergeKind) {
    if (mergeKind == MergeKind.superclass && member.target.isAbstract) {
      (abstractMembers ??= <Declaration>[]).add(member);
    }
  }

  /// When merging `aList` and `bList`, [member] was only found in `bList`.
  ///
  /// If [mergeKind] is `MergeKind.superclass` [member] is being inherited from
  /// a superclass.
  ///
  /// If [mergeKind] is `MergeKind.interfaces`, [member] is ignored for now.
  ///
  /// If [mergeKind] is `MergeKind.supertypes`, [member] is implicitly
  /// abstract, and not implemented.
  void handleOnlyB(
      KernelClassBuilder cls, Declaration member, MergeKind mergeKind) {
    Member target = member.target;
    if (mergeKind == MergeKind.supertypes ||
        (mergeKind == MergeKind.superclass && target.isAbstract)) {
      if (isNameVisibleIn(target.name, cls.library)) {
        (abstractMembers ??= <Declaration>[]).add(member);
      }
    }
    if (member.parent != objectClass &&
        target.name == noSuchMethodName &&
        !target.isAbstract) {
      hasNoSuchMethod = true;
    }
  }

  ClassHierarchyNode build() {
    if (cls.isPatch) {
      // TODO(ahe): What about patch classes. Have we injected patched members
      // into the class-builder's scope?
      return null;
    }
    ClassHierarchyNode supernode;
    if (objectClass != cls) {
      supernode = hierarchy.getNodeFromType(cls.supertype);
      if (supernode == null) {
        supernode = hierarchy.getNodeFromClass(objectClass);
      }
      assert(supernode != null);
    }

    Scope scope = cls.scope;
    if (cls.isMixinApplication) {
      Declaration mixin = cls.mixedInType.declaration;
      inferMixinApplication();
      while (mixin.isNamedMixinApplication) {
        KernelClassBuilder named = mixin;
        mixin = named.mixedInType.declaration;
      }
      if (mixin is KernelClassBuilder) {
        scope = mixin.scope.computeMixinScope();
      }
    }

    /// Members (excluding setters) declared in [cls].
    List<Declaration> localMembers =
        new List<Declaration>.from(scope.local.values)
          ..sort(compareDeclarations);

    /// Setters declared in [cls].
    List<Declaration> localSetters =
        new List<Declaration>.from(scope.setters.values)
          ..sort(compareDeclarations);

    // Add implied setters from fields in [localMembers].
    localSetters = mergeAccessors(cls, localMembers, localSetters);

    /// Members (excluding setters) declared in [cls] or its superclasses. This
    /// includes static methods of [cls], but not its superclasses.
    List<Declaration> classMembers;

    /// Setters declared in [cls] or its superclasses. This includes static
    /// setters of [cls], but not its superclasses.
    List<Declaration> classSetters;

    /// Members (excluding setters) inherited from interfaces. This contains no static
    /// members. Is null if no interfaces are implemented by this class or its
    /// superclasses.
    List<Declaration> interfaceMembers;

    /// Setters inherited from interfaces. This contains no static setters. Is
    /// null if no interfaces are implemented by this class or its
    /// superclasses.
    List<Declaration> interfaceSetters;

    List<KernelTypeBuilder> superclasses;

    List<KernelTypeBuilder> interfaces;

    int maxInheritancePath;

    if (supernode == null) {
      // This should be Object.
      classMembers = localMembers;
      classSetters = localSetters;
      superclasses = new List<KernelTypeBuilder>(0);
      interfaces = new List<KernelTypeBuilder>(0);
      maxInheritancePath = 0;
    } else {
      maxInheritancePath = supernode.maxInheritancePath + 1;
      superclasses =
          new List<KernelTypeBuilder>(supernode.superclasses.length + 1);
      superclasses.setRange(0, superclasses.length - 1,
          substSupertypes(cls.supertype, supernode.superclasses));
      superclasses[superclasses.length - 1] = cls.supertype;

      classMembers = merge(
          cls, localMembers, supernode.classMembers, MergeKind.superclass);
      classSetters = merge(
          cls, localSetters, supernode.classSetters, MergeKind.superclass);

      // Check if local members conflict with inherited setters. This check has
      // already been performed in the superclass, so we only need to check the
      // local members.
      merge(cls, localMembers, classSetters, MergeKind.accessors);

      // Check if local setters conflict with inherited members. As above, we
      // only need to check the local setters.
      merge(cls, localSetters, classMembers, MergeKind.accessors);

      List<KernelTypeBuilder> directInterfaces = cls.interfaces;
      if (cls.isMixinApplication) {
        if (directInterfaces == null) {
          directInterfaces = <KernelTypeBuilder>[cls.mixedInType];
        } else {
          directInterfaces = <KernelTypeBuilder>[cls.mixedInType]
            ..addAll(directInterfaces);
        }
      }
      if (directInterfaces != null) {
        MergeResult result = mergeInterfaces(cls, supernode, directInterfaces);
        interfaceMembers = result.mergedMembers;
        interfaceSetters = result.mergedSetters;
        interfaces = <KernelTypeBuilder>[];
        if (supernode.interfaces != null) {
          List<KernelTypeBuilder> types =
              substSupertypes(cls.supertype, supernode.interfaces);
          for (int i = 0; i < types.length; i++) {
            addInterface(interfaces, superclasses, types[i]);
          }
        }
        for (int i = 0; i < directInterfaces.length; i++) {
          KernelTypeBuilder directInterface = directInterfaces[i];
          addInterface(interfaces, superclasses, directInterface);
          ClassHierarchyNode interfaceNode =
              hierarchy.getNodeFromType(directInterface);
          if (interfaceNode != null) {
            if (maxInheritancePath < interfaceNode.maxInheritancePath + 1) {
              maxInheritancePath = interfaceNode.maxInheritancePath + 1;
            }
            List<KernelTypeBuilder> types =
                substSupertypes(directInterface, interfaceNode.superclasses);
            for (int i = 0; i < types.length; i++) {
              addInterface(interfaces, superclasses, types[i]);
            }

            if (interfaceNode.interfaces != null) {
              List<KernelTypeBuilder> types =
                  substSupertypes(directInterface, interfaceNode.interfaces);
              for (int i = 0; i < types.length; i++) {
                addInterface(interfaces, superclasses, types[i]);
              }
            }
          }
        }
      } else {
        interfaceMembers = supernode.interfaceMembers;
        interfaceSetters = supernode.interfaceSetters;
        interfaces = substSupertypes(cls.supertype, supernode.interfaces);
      }
      if (interfaceMembers != null) {
        interfaceMembers =
            merge(cls, classMembers, interfaceMembers, MergeKind.supertypes);

        // Check if class setters conflict with members inherited from
        // interfaces.
        merge(cls, classSetters, interfaceMembers, MergeKind.accessors);
      }
      if (interfaceSetters != null) {
        interfaceSetters =
            merge(cls, classSetters, interfaceSetters, MergeKind.supertypes);

        // Check if class members conflict with setters inherited from
        // interfaces.
        merge(cls, classMembers, interfaceSetters, MergeKind.accessors);
      }
    }
    if (abstractMembers != null && !cls.isAbstract) {
      if (!hasNoSuchMethod) {
        reportMissingMembers(cls);
      } else {
        installNsmHandlers(cls);
      }
    }
    return new ClassHierarchyNode(
      cls,
      classMembers,
      classSetters,
      interfaceMembers,
      interfaceSetters,
      superclasses,
      interfaces,
      maxInheritancePath,
    );
  }

  List<KernelTypeBuilder> substSupertypes(
      KernelNamedTypeBuilder supertype, List<KernelTypeBuilder> supertypes) {
    Declaration declaration = supertype.declaration;
    if (declaration is! KernelClassBuilder) return supertypes;
    KernelClassBuilder cls = declaration;
    List<TypeVariableBuilder<TypeBuilder, Object>> typeVariables =
        cls.typeVariables;
    if (typeVariables == null) return supertypes;
    Map<TypeVariableBuilder<TypeBuilder, Object>, TypeBuilder> substitution =
        <TypeVariableBuilder<TypeBuilder, Object>, TypeBuilder>{};
    List<KernelTypeBuilder> arguments =
        supertype.arguments ?? computeDefaultTypeArguments(supertype);
    for (int i = 0; i < typeVariables.length; i++) {
      substitution[typeVariables[i]] = arguments[i];
    }
    List<KernelTypeBuilder> result;
    for (int i = 0; i < supertypes.length; i++) {
      KernelTypeBuilder supertype = supertypes[i];
      KernelTypeBuilder substed = supertype.subst(substitution);
      if (supertype != substed) {
        result ??= supertypes.toList();
        result[i] = substed;
      }
    }
    return result ?? supertypes;
  }

  List<KernelTypeBuilder> computeDefaultTypeArguments(KernelTypeBuilder type) {
    KernelClassBuilder cls = type.declaration;
    List<KernelTypeBuilder> result =
        new List<KernelTypeBuilder>(cls.typeVariables.length);
    for (int i = 0; i < result.length; ++i) {
      result[i] = cls.typeVariables[i].defaultType;
    }
    return result;
  }

  KernelTypeBuilder addInterface(List<KernelTypeBuilder> interfaces,
      List<KernelTypeBuilder> superclasses, KernelTypeBuilder type) {
    ClassHierarchyNode node = hierarchy.getNodeFromType(type);
    if (node == null) return null;
    int depth = node.depth;
    int myDepth = superclasses.length;
    if (depth < myDepth && superclasses[depth].declaration == node.cls) {
      // This is a potential conflict.
      return superclasses[depth];
    } else {
      for (int i = 0; i < interfaces.length; i++) {
        // This is a quadratic algorithm, but normally, the number of
        // interfaces is really small.
        if (interfaces[i].declaration == type.declaration) {
          // This is a potential conflict.
          return interfaces[i];
        }
      }
    }
    interfaces.add(type);
    return null;
  }

  MergeResult mergeInterfaces(KernelClassBuilder cls,
      ClassHierarchyNode supernode, List<KernelTypeBuilder> interfaces) {
    List<List<Declaration>> memberLists =
        new List<List<Declaration>>(interfaces.length + 1);
    List<List<Declaration>> setterLists =
        new List<List<Declaration>>(interfaces.length + 1);
    memberLists[0] = supernode.interfaceMembers;
    setterLists[0] = supernode.interfaceSetters;
    for (int i = 0; i < interfaces.length; i++) {
      ClassHierarchyNode interfaceNode =
          hierarchy.getNodeFromType(interfaces[i]);
      if (interfaceNode == null) {
        memberLists[i + 1] = null;
        setterLists[i + 1] = null;
      } else {
        memberLists[i + 1] =
            interfaceNode.interfaceMembers ?? interfaceNode.classMembers;
        setterLists[i + 1] =
            interfaceNode.interfaceSetters ?? interfaceNode.classSetters;
      }
    }
    return new MergeResult(
        mergeLists(cls, memberLists), mergeLists(cls, setterLists));
  }

  List<Declaration> mergeLists(
      KernelClassBuilder cls, List<List<Declaration>> input) {
    // This is a k-way merge sort (where k is `input.length + 1`). We merge the
    // lists pairwise, which reduces the number of lists to merge by half on
    // each iteration. Consequently, we perform O(log k) merges.
    while (input.length > 1) {
      List<List<Declaration>> output = <List<Declaration>>[];
      for (int i = 0; i < input.length - 1; i += 2) {
        List<Declaration> first = input[i];
        List<Declaration> second = input[i + 1];
        if (first == null) {
          output.add(second);
        } else if (second == null) {
          output.add(first);
        } else {
          output.add(merge(cls, first, second, MergeKind.interfaces));
        }
      }
      if (input.length.isOdd) {
        output.add(input.last);
      }
      input = output;
    }
    return input.single;
  }

  /// Merge [and check] accessors. This entails copying mutable fields to
  /// setters to simulate implied setters, and checking that setters don't
  /// override regular methods.
  List<Declaration> mergeAccessors(KernelClassBuilder cls,
      List<Declaration> members, List<Declaration> setters) {
    final List<Declaration> mergedSetters = new List<Declaration>.filled(
        members.length + setters.length, null,
        growable: true);
    int storeIndex = 0;
    int i = 0;
    int j = 0;
    while (i < members.length && j < setters.length) {
      final Declaration member = members[i];
      final Declaration setter = setters[j];
      final int compare = compareDeclarations(member, setter);
      if (compare == 0) {
        mergedSetters[storeIndex++] = setter;
        i++;
        j++;
      } else if (compare < 0) {
        if (impliesSetter(member)) {
          mergedSetters[storeIndex++] = member;
        }
        i++;
      } else {
        mergedSetters[storeIndex++] = setters[j];
        j++;
      }
    }
    while (i < members.length) {
      final Declaration member = members[i];
      if (impliesSetter(member)) {
        mergedSetters[storeIndex++] = member;
      }
      i++;
    }
    while (j < setters.length) {
      mergedSetters[storeIndex++] = setters[j];
      j++;
    }

    if (storeIndex == j) {
      return setters;
    } else {
      return mergedSetters..length = storeIndex;
    }
  }

  void reportMissingMembers(KernelClassBuilder cls) {
    Map<String, LocatedMessage> contextMap = <String, LocatedMessage>{};
    for (int i = 0; i < abstractMembers.length; i++) {
      Declaration declaration = abstractMembers[i];
      Member target = declaration.target;
      if (isNameVisibleIn(target.name, cls.library)) {
        String name = declaration.fullNameForErrors;
        String parentName = declaration.parent.fullNameForErrors;
        String displayName =
            declaration.isSetter ? "$parentName.$name=" : "$parentName.$name";
        contextMap[displayName] = templateMissingImplementationCause
            .withArguments(displayName)
            .withLocation(
                declaration.fileUri, declaration.charOffset, name.length);
      }
    }
    if (contextMap.isEmpty) return;
    List<String> names = new List<String>.from(contextMap.keys)..sort();
    List<LocatedMessage> context = <LocatedMessage>[];
    for (int i = 0; i < names.length; i++) {
      context.add(contextMap[names[i]]);
    }
    cls.addProblem(
        templateMissingImplementationNotAbstract.withArguments(
            cls.fullNameForErrors, names),
        cls.charOffset,
        cls.fullNameForErrors.length,
        context: context);
  }

  void installNsmHandlers(KernelClassBuilder cls) {
    // TOOD(ahe): Implement this.
  }

  List<Declaration> merge(KernelClassBuilder cls, List<Declaration> aList,
      List<Declaration> bList, MergeKind mergeKind) {
    final List<Declaration> result = new List<Declaration>.filled(
        aList.length + bList.length, null,
        growable: true);
    int storeIndex = 0;
    int i = 0;
    int j = 0;
    while (i < aList.length && j < bList.length) {
      final Declaration a = aList[i];
      final Declaration b = bList[j];
      if (mergeKind == MergeKind.interfaces && a.isStatic) {
        i++;
        continue;
      }
      if (b.isStatic) {
        j++;
        continue;
      }
      final int compare = compareDeclarations(a, b);
      if (compare == 0) {
        result[storeIndex++] = handleMergeConflict(cls, a, b, mergeKind);
        i++;
        j++;
      } else if (compare < 0) {
        handleOnlyA(a, mergeKind);
        result[storeIndex++] = a;
        i++;
      } else {
        handleOnlyB(cls, b, mergeKind);
        result[storeIndex++] = b;
        j++;
      }
    }
    while (i < aList.length) {
      final Declaration a = aList[i];
      if (mergeKind != MergeKind.interfaces || !a.isStatic) {
        handleOnlyA(a, mergeKind);
        result[storeIndex++] = a;
      }
      i++;
    }
    while (j < bList.length) {
      final Declaration b = bList[j];
      if (!b.isStatic) {
        handleOnlyB(cls, b, mergeKind);
        result[storeIndex++] = b;
      }
      j++;
    }
    if (aList.isEmpty && storeIndex == bList.length) return bList;
    if (bList.isEmpty && storeIndex == aList.length) return aList;
    return result..length = storeIndex;
  }

  void inferMixinApplication() {
    Class kernelClass = cls.target;
    Supertype kernelMixedInType = kernelClass.mixedInType;
    if (kernelMixedInType == null) return;
    List<DartType> typeArguments = kernelMixedInType.typeArguments;
    if (typeArguments.isEmpty || typeArguments.first is! UnknownType) return;
    new BuilderMixinInferrer(
            cls,
            hierarchy.coreTypes,
            new TypeBuilderConstraintGatherer(
                hierarchy, kernelMixedInType.classNode.typeParameters))
        .infer(kernelClass);
    List<KernelTypeBuilder> inferredArguments =
        new List<KernelTypeBuilder>(typeArguments.length);
    for (int i = 0; i < typeArguments.length; i++) {
      inferredArguments[i] =
          hierarchy.loader.computeTypeBuilder(typeArguments[i]);
    }
    KernelNamedTypeBuilder mixedInType = cls.mixedInType;
    mixedInType.arguments = inferredArguments;
  }
}

class ClassHierarchyNode {
  /// The class corresponding to this hierarchy node.
  final KernelClassBuilder cls;

  /// All the members of this class including [classMembers] of its
  /// superclasses. The members are sorted by [compareDeclarations].
  final List<Declaration> classMembers;

  /// Similar to [classMembers] but for setters.
  final List<Declaration> classSetters;

  /// All the interface members of this class including [interfaceMembers] of
  /// its supertypes. The members are sorted by [compareDeclarations].
  ///
  /// In addition to the members of [classMembers] this also contains members
  /// from interfaces.
  ///
  /// This may be null, in which case [classMembers] is the interface members.
  final List<Declaration> interfaceMembers;

  /// Similar to [interfaceMembers] but for setters.
  ///
  /// This may be null, in which case [classSetters] is the interface setters.
  final List<Declaration> interfaceSetters;

  /// All superclasses of [cls] excluding itself. The classes are sorted by
  /// depth from the root (Object) in ascending order.
  final List<KernelTypeBuilder> superclasses;

  /// The list of all classes implemented by [cls] and its supertypes excluding
  /// any classes from [superclasses].
  final List<KernelTypeBuilder> interfaces;

  /// The longest inheritance path from [cls] to `Object`.
  final int maxInheritancePath;

  int get depth => superclasses.length;

  ClassHierarchyNode(
      this.cls,
      this.classMembers,
      this.classSetters,
      this.interfaceMembers,
      this.interfaceSetters,
      this.superclasses,
      this.interfaces,
      this.maxInheritancePath);

  /// Returns a list of all supertypes of [cls], including this node.
  List<ClassHierarchyNode> computeAllSuperNodes(
      ClassHierarchyBuilder hierarchy) {
    List<ClassHierarchyNode> result = new List<ClassHierarchyNode>(
        1 + superclasses.length + interfaces.length);
    for (int i = 0; i < superclasses.length; i++) {
      Declaration declaration = superclasses[i].declaration;
      if (declaration is KernelClassBuilder) {
        result[i] = hierarchy.getNodeFromClass(declaration);
      }
    }
    for (int i = 0; i < interfaces.length; i++) {
      Declaration declaration = interfaces[i].declaration;
      if (declaration is KernelClassBuilder) {
        result[i + superclasses.length] =
            hierarchy.getNodeFromClass(declaration);
      }
    }
    return result..last = this;
  }

  String toString([StringBuffer sb]) {
    sb ??= new StringBuffer();
    sb
      ..write(cls.fullNameForErrors)
      ..writeln(":");
    if (maxInheritancePath != this.depth) {
      sb
        ..write("  Longest path to Object: ")
        ..writeln(maxInheritancePath);
    }
    sb..writeln("  superclasses:");
    int depth = 0;
    for (KernelTypeBuilder superclass in superclasses) {
      sb.write("  " * (depth + 2));
      if (depth != 0) sb.write("-> ");
      superclass.printOn(sb);
      sb.writeln();
      depth++;
    }
    if (interfaces != null) {
      sb.write("  interfaces:");
      bool first = true;
      for (KernelTypeBuilder i in interfaces) {
        if (!first) sb.write(",");
        sb.write(" ");
        i.printOn(sb);
        first = false;
      }
      sb.writeln();
    }
    printMembers(classMembers, sb, "classMembers");
    printMembers(classSetters, sb, "classSetters");
    if (interfaceMembers != null) {
      printMembers(interfaceMembers, sb, "interfaceMembers");
    }
    if (interfaceSetters != null) {
      printMembers(interfaceSetters, sb, "interfaceSetters");
    }
    return "$sb";
  }

  void printMembers(
      List<Declaration> members, StringBuffer sb, String heading) {
    sb.write("  ");
    sb.write(heading);
    sb.writeln(":");
    for (Declaration member in members) {
      sb
        ..write("    ")
        ..write(member.parent.fullNameForErrors)
        ..write(".")
        ..write(member.fullNameForErrors)
        ..writeln();
    }
  }

  static int compareMaxInheritancePath(
      ClassHierarchyNode a, ClassHierarchyNode b) {
    return b.maxInheritancePath.compareTo(a.maxInheritancePath);
  }
}

class MergeResult {
  final List<Declaration> mergedMembers;

  final List<Declaration> mergedSetters;

  MergeResult(this.mergedMembers, this.mergedSetters);
}

enum MergeKind {
  /// Merging superclass members with the current class.
  superclass,

  /// Merging two interfaces.
  interfaces,

  /// Merging class members with interface members.
  supertypes,

  /// Merging members with inherited setters, or setters with inherited
  /// members.
  accessors,
}

List<LocatedMessage> inheritedConflictContext(Declaration a, Declaration b) {
  return inheritedConflictContextKernel(
      a.target, b.target, a.fullNameForErrors.length);
}

List<LocatedMessage> inheritedConflictContextKernel(
    Member a, Member b, int length) {
  // TODO(ahe): Delete this method when it isn't used by [InterfaceResolver].
  int compare = "${a.fileUri}".compareTo("${b.fileUri}");
  if (compare == 0) {
    compare = a.fileOffset.compareTo(b.fileOffset);
  }
  Member first;
  Member second;
  if (compare < 0) {
    first = a;
    second = b;
  } else {
    first = b;
    second = a;
  }
  return <LocatedMessage>[
    messageInheritedMembersConflictCause1.withLocation(
        first.fileUri, first.fileOffset, length),
    messageInheritedMembersConflictCause2.withLocation(
        second.fileUri, second.fileOffset, length),
  ];
}

class BuilderMixinInferrer extends MixinInferrer {
  final KernelClassBuilder cls;

  BuilderMixinInferrer(
      this.cls, CoreTypes coreTypes, TypeBuilderConstraintGatherer gatherer)
      : super(coreTypes, gatherer);

  Supertype asInstantiationOf(Supertype type, Class superclass) {
    InterfaceType interfaceType =
        gatherer.getTypeAsInstanceOf(type.asInterfaceType, superclass);
    if (interfaceType == null) return null;
    return new Supertype(interfaceType.classNode, interfaceType.typeArguments);
  }

  void reportProblem(Message message, Class kernelClass) {
    int length = cls.isMixinApplication ? 1 : cls.fullNameForErrors.length;
    cls.addProblem(message, cls.charOffset, length);
  }
}

class TypeBuilderConstraintGatherer extends TypeConstraintGatherer
    with StandardBounds {
  final ClassHierarchyBuilder hierarchy;

  TypeBuilderConstraintGatherer(
      this.hierarchy, Iterable<TypeParameter> typeParameters)
      : super.subclassing(typeParameters);

  @override
  Class get objectClass => hierarchy.objectKernelClass;

  @override
  Class get functionClass => hierarchy.functionKernelClass;

  @override
  Class get futureOrClass => hierarchy.futureOrKernelClass;

  @override
  Class get nullClass => hierarchy.nullKernelClass;

  @override
  InterfaceType get nullType => nullClass.rawType;

  @override
  InterfaceType get objectType => objectClass.rawType;

  @override
  InterfaceType get rawFunctionType => functionClass.rawType;

  @override
  void addLowerBound(TypeConstraint constraint, DartType lower) {
    constraint.lower = getStandardUpperBound(constraint.lower, lower);
  }

  @override
  void addUpperBound(TypeConstraint constraint, DartType upper) {
    constraint.upper = getStandardLowerBound(constraint.upper, upper);
  }

  @override
  Member getInterfaceMember(Class class_, Name name, {bool setter: false}) {
    return null;
  }

  @override
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass) {
    return hierarchy.getKernelTypeAsInstanceOf(type, superclass);
  }

  @override
  InterfaceType futureType(DartType type) {
    return new InterfaceType(hierarchy.futureKernelClass, <DartType>[type]);
  }

  @override
  bool isSubtypeOf(DartType subtype, DartType supertype) {
    return hierarchy.types.isSubtypeOfKernel(subtype, supertype);
  }

  @override
  InterfaceType getLegacyLeastUpperBound(
      InterfaceType type1, InterfaceType type2) {
    return hierarchy.getKernelLegacyLeastUpperBound(type1, type2);
  }
}
