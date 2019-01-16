// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart'
    show Library, Member, Name, Procedure, ProcedureKind;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import '../messages.dart'
    show
        LocatedMessage,
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

import 'kernel_builder.dart'
    show
        Declaration,
        LibraryBuilder,
        KernelClassBuilder,
        KernelNamedTypeBuilder,
        KernelTypeBuilder;

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
  final Map<KernelClassBuilder, ClassHierarchyNode> nodes =
      <KernelClassBuilder, ClassHierarchyNode>{};

  final KernelClassBuilder objectClass;

  bool hasNoSuchMethod = false;

  List<Declaration> abstractMembers = null;

  ClassHierarchyBuilder(this.objectClass);

  /// A merge conflict arises when merging two lists that each have an element
  /// with the same name.
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

  void add(KernelClassBuilder cls) {
    assert(!hasNoSuchMethod);
    assert(abstractMembers == null);
    if (cls.isPatch) {
      // TODO(ahe): What about patch classes. Have we injected patched members
      // into the class-builder's scope?
      return;
    }
    ClassHierarchyNode supernode;
    if (objectClass != cls) {
      supernode = getNode(cls.supertype);
      if (supernode == null) {
        supernode = nodes[objectClass];
        if (supernode == null) {
          add(objectClass);
          supernode = nodes[objectClass];
        }
      }
      assert(supernode != null);
    }

    Scope scope = cls.scope;
    if (cls.isMixinApplication) {
      Declaration mixin = getDeclaration(cls.mixedInType);
      while (mixin.isNamedMixinApplication) {
        KernelClassBuilder named = mixin;
        mixin = getDeclaration(named.mixedInType);
      }
      if (mixin is KernelClassBuilder) {
        scope = mixin.scope;
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

    if (supernode == null) {
      // This should be Object.
      classMembers = localMembers;
      classSetters = localSetters;
    } else {
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

      List<KernelTypeBuilder> interfaces = cls.interfaces;
      if (cls.isMixinApplication) {
        if (interfaces == null) {
          interfaces = <KernelTypeBuilder>[cls.mixedInType];
        } else {
          interfaces = <KernelTypeBuilder>[cls.mixedInType]..addAll(interfaces);
        }
      }
      if (interfaces != null) {
        MergeResult result = mergeInterfaces(cls, supernode, interfaces);
        interfaceMembers = result.mergedMembers;
        interfaceSetters = result.mergedSetters;
      } else {
        interfaceMembers = supernode.interfaceMembers;
        interfaceSetters = supernode.interfaceSetters;
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
    nodes[cls] = new ClassHierarchyNode(cls, scope, classMembers, classSetters,
        interfaceMembers, interfaceSetters);

    if (abstractMembers != null && !cls.isAbstract) {
      if (!hasNoSuchMethod) {
        reportMissingMembers(cls);
      } else {
        installNsmHandlers(cls);
      }
    }
    hasNoSuchMethod = false;
    abstractMembers = null;
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
      ClassHierarchyNode interfaceNode = getNode(interfaces[i]);
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

  ClassHierarchyNode getNode(KernelTypeBuilder type) {
    Declaration declaration = getDeclaration(type);
    if (declaration is KernelClassBuilder) {
      ClassHierarchyNode node = nodes[declaration];
      if (node == null) {
        bool savedHasNoSuchMethod = hasNoSuchMethod;
        hasNoSuchMethod = false;
        List<Declaration> savedAbstractMembers = abstractMembers;
        abstractMembers = null;
        add(declaration);
        hasNoSuchMethod = savedHasNoSuchMethod;
        abstractMembers = savedAbstractMembers;
        node = nodes[declaration];
      }
      return node;
    }
    return null;
  }

  Declaration getDeclaration(KernelTypeBuilder type) {
    return type is KernelNamedTypeBuilder ? type.declaration : null;
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
}

class ClassHierarchyNode {
  /// The class corresponding to this hierarchy node.
  final KernelClassBuilder cls;

  /// The local members of [cls]. For regular classes, this is simply
  /// `cls.scope`, but for mixin-applications this is the mixed-in type's
  /// scope. The members are sorted in order of declaration.
  // TODO(ahe): Do we need to copy the scope from the mixed-in type to remove
  // static members?
  final Scope localMembers;

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
  final List<Declaration> interfaceMembers;

  /// Similar to [interfaceMembers] but for setters.
  final List<Declaration> interfaceSetters;

  ClassHierarchyNode(this.cls, this.localMembers, this.classMembers,
      this.classSetters, this.interfaceMembers, this.interfaceSetters);
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
