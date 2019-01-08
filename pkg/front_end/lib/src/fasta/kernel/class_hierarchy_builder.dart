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

class ClassHierarchyBuilder {
  final Map<KernelClassBuilder, ClassHierarchyNode> nodes =
      <KernelClassBuilder, ClassHierarchyNode>{};

  final KernelClassBuilder objectClass;

  bool hasNoSuchMethod = false;

  int abstractMemberCount = 0;

  ClassHierarchyBuilder(this.objectClass);

  Declaration handleOverride(KernelClassBuilder cls, Declaration member,
      Declaration superMember, MergeKind mergeKind) {
    if (member.next != null || superMember.next != null) {
      // Don't check overrides involving duplicated members.
      return member;
    }
    Member target = member.target;
    Member superTarget = superMember.target;
    if ((memberKind(target) ?? ProcedureKind.Getter) !=
        (memberKind(superTarget) ?? ProcedureKind.Getter)) {
      String name = member.fullNameForErrors;
      if (mergeKind == MergeKind.interfaces) {
        cls.addProblem(messageInheritedMembersConflict, cls.charOffset,
            cls.fullNameForErrors.length,
            context: <LocatedMessage>[
              messageInheritedMembersConflictCause1.withLocation(
                  member.fileUri, member.charOffset, name.length),
              messageInheritedMembersConflictCause2.withLocation(
                  superMember.fileUri, superMember.charOffset, name.length),
            ]);
      } else {
        cls.addProblem(messageDeclaredMemberConflictsWithInheritedMember,
            member.charOffset, name.length,
            context: <LocatedMessage>[
              messageDeclaredMemberConflictsWithInheritedMemberCause
                  .withLocation(
                      superMember.fileUri, superMember.charOffset, name.length)
            ]);
      }
    }
    if (target.name == noSuchMethodName && !target.isAbstract) {
      hasNoSuchMethod = true;
    }
    Declaration result = member;
    if (mergeKind == MergeKind.interfaces) {
      // TODO(ahe): Combine the signatures of member and superMember.
    } else if (target.isAbstract) {
      if (!superTarget.isAbstract) {
        // An abstract method doesn't override an implemention inherited from a
        // superclass.
        result = superMember;
      } else {
        abstractMemberCount++;
      }
    }
    return result;
  }

  void handleNewMember(Declaration member, MergeKind mergeKind) {
    Member target = member.target;
    if (mergeKind == MergeKind.superclass && target.isAbstract) {
      abstractMemberCount++;
    }
  }

  void handleInheritance(
      KernelClassBuilder cls, Declaration member, MergeKind mergeKind) {
    Member target = member.target;
    if (mergeKind == MergeKind.superclass && target.isAbstract) {
      if (isNameVisibleIn(target.name, cls.library)) {
        abstractMemberCount++;
      }
    }
    if (member.parent != objectClass &&
        target.name == noSuchMethodName &&
        !target.isAbstract) {
      hasNoSuchMethod = true;
    }
  }

  void add(KernelClassBuilder cls) {
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
      if (mixin is KernelClassBuilder) {
        scope = mixin.scope;
      }
    }
    List<Declaration> sortedLocals =
        new List<Declaration>.from(scope.local.values)
          ..sort(compareDeclarations);
    List<Declaration> sortedSetters =
        new List<Declaration>.from(scope.setters.values)
          ..sort(compareDeclarations);
    List<Declaration> allMembers;
    List<Declaration> allSetters;
    List<Declaration> interfaceMembers;
    List<Declaration> interfaceSetters;
    if (supernode == null) {
      // This should be Object.
      interfaceMembers = allMembers = sortedLocals;
      interfaceSetters = allSetters = sortedSetters;
    } else {
      allMembers = merge(
          cls, sortedLocals, supernode.classMembers, MergeKind.superclass);
      allSetters = merge(
          cls, sortedSetters, supernode.classSetters, MergeKind.superclass);
      List<KernelTypeBuilder> interfaces = cls.interfaces;
      if (interfaces != null) {
        MergeResult result = mergeInterfaces(cls, supernode, interfaces);
        interfaceMembers = result.mergedMembers;
        interfaceSetters = result.mergedSetters;
      } else {
        interfaceMembers = allMembers;
        interfaceSetters = allSetters;
      }
    }
    nodes[cls] = new ClassHierarchyNode(
        cls, scope, allMembers, allSetters, interfaceMembers, interfaceSetters);
    mergeAccessors(cls, allMembers, allSetters);

    if (abstractMemberCount != 0 && !cls.isAbstract) {
      if (!hasNoSuchMethod) {
        reportMissingMembers(cls, allMembers, allSetters);
      }
      installNsmHandlers(cls);
    }
    hasNoSuchMethod = false;
    abstractMemberCount = 0;
  }

  MergeResult mergeInterfaces(KernelClassBuilder cls,
      ClassHierarchyNode supernode, List<KernelTypeBuilder> interfaces) {
    List<List<Declaration>> memberLists =
        List<List<Declaration>>(interfaces.length + 1);
    List<List<Declaration>> setterLists =
        List<List<Declaration>>(interfaces.length + 1);
    memberLists[0] = supernode.interfaceMembers;
    setterLists[0] = supernode.interfaceSetters;
    for (int i = 0; i < interfaces.length; i++) {
      ClassHierarchyNode interfaceNode = getNode(interfaces[i]);
      if (interfaceNode == null) {
        memberLists[i + 1] = <Declaration>[];
        setterLists[i + 1] = <Declaration>[];
      } else {
        memberLists[i + 1] = interfaceNode.interfaceMembers;
        setterLists[i + 1] = interfaceNode.interfaceSetters;
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
        output.add(merge(cls, input[i], input[i + 1], MergeKind.interfaces));
      }
      if (input.length.isOdd) {
        output.add(input.last);
      }
      input = output;
    }
    return input.single;
  }

  /// Merge [and check] accessors. This entails removing setters corresponding
  /// to fields, and checking that setters don't override regular methods.
  void mergeAccessors(KernelClassBuilder cls, List<Declaration> allMembers,
      List<Declaration> allSetters) {
    List<Declaration> overriddenSetters;
    int i = 0;
    int j = 0;
    while (i < allMembers.length && j < allSetters.length) {
      Declaration member = allMembers[i];
      Declaration setter = allSetters[j];
      final int compare = compareDeclarations(member, setter);
      if (compare == 0) {
        if (member.isField) {
          // TODO(ahe): What happens if we have both a field and a setter
          // declared in the same class?
          if (!member.isFinal && !member.isConst) {
            // The field overrides the setter.
            (overriddenSetters ??= <Declaration>[]).add(setter);
            Member target = setter.target;
            if (target.isAbstract) {
              abstractMemberCount--;
            }
          }
        } else if (!member.isGetter) {
          String name = member.fullNameForErrors;
          cls.library.addProblem(
              messageDeclaredMemberConflictsWithInheritedMember,
              member.charOffset,
              name.length,
              member.fileUri,
              context: <LocatedMessage>[
                messageDeclaredMemberConflictsWithInheritedMemberCause
                    .withLocation(
                        setter.fileUri, setter.charOffset, name.length)
              ]);
        }
        i++;
        j++;
      } else if (compare < 0) {
        i++;
      } else {
        j++;
      }
    }
    // One of of the two lists is now exhausted. What remains in the other list
    // cannot be a conflict.

    if (overriddenSetters != null) {
      // Remove [overriddenSetters] from [allSetters] by copying [allSetters]
      // to itself.
      int i = 0;
      int j = 0;
      int storeIndex = 0;
      while (i < allSetters.length && j < overriddenSetters.length) {
        if (allSetters[i] == overriddenSetters[j]) {
          i++;
          j++;
        } else {
          allSetters[storeIndex++] = allSetters[i++];
        }
      }
      while (i < allSetters.length) {
        allSetters[storeIndex++] = allSetters[i++];
      }
      allSetters.length = storeIndex;
    }
  }

  void reportMissingMembers(KernelClassBuilder cls,
      List<Declaration> allMembers, List<Declaration> allSetters) {
    List<LocatedMessage> context = <LocatedMessage>[];
    List<String> missingNames = <String>[];
    for (int j = 0; j < 2; j++) {
      List<Declaration> members = j == 0 ? allMembers : allSetters;
      for (int i = 0; i < members.length; i++) {
        Declaration declaration = members[i];
        Member target = declaration.target;
        if (target.isAbstract && isNameVisibleIn(target.name, cls.library)) {
          String name = declaration.fullNameForErrors;
          String parentName = declaration.parent.fullNameForErrors;
          String displayName =
              declaration.isSetter ? "$parentName.$name=" : "$parentName.$name";
          missingNames.add(displayName);
          context.add(templateMissingImplementationCause
              .withArguments(displayName)
              .withLocation(
                  declaration.fileUri, declaration.charOffset, name.length));
        }
      }
    }
    cls.addProblem(
        templateMissingImplementationNotAbstract.withArguments(
            cls.fullNameForErrors, missingNames),
        cls.charOffset,
        cls.fullNameForErrors.length,
        context: context);
  }

  void installNsmHandlers(KernelClassBuilder cls) {
    // TOOD(ahe): Implement this.
  }

  ClassHierarchyNode getNode(KernelTypeBuilder type) {
    if (type is KernelNamedTypeBuilder) {
      Declaration declaration = type.declaration;
      if (declaration is KernelClassBuilder) {
        ClassHierarchyNode node = nodes[declaration];
        if (node == null && declaration is KernelClassBuilder) {
          add(declaration);
          node = nodes[declaration];
        }
        return node;
      }
    }
    return null;
  }

  Declaration getDeclaration(KernelTypeBuilder type) {
    return type is KernelNamedTypeBuilder ? type.declaration : null;
  }

  List<Declaration> merge(
      KernelClassBuilder cls,
      List<Declaration> localMembers,
      List<Declaration> superMembers,
      MergeKind mergeKind) {
    final List<Declaration> mergedMembers = new List<Declaration>.filled(
        localMembers.length + superMembers.length, null,
        growable: true);

    int mergedMemberCount = 0;

    int i = 0;
    int j = 0;
    while (i < localMembers.length && j < superMembers.length) {
      final Declaration localMember = localMembers[i];
      final Declaration superMember = superMembers[j];
      final int compare = compareDeclarations(localMember, superMember);
      if (compare == 0) {
        mergedMembers[mergedMemberCount++] =
            handleOverride(cls, localMember, superMember, mergeKind);
        i++;
        j++;
      } else if (compare < 0) {
        handleNewMember(localMember, mergeKind);
        mergedMembers[mergedMemberCount++] = localMember;
        i++;
      } else {
        handleInheritance(cls, superMember, mergeKind);
        mergedMembers[mergedMemberCount++] = superMember;
        j++;
      }
    }
    while (i < localMembers.length) {
      final Declaration localMember = localMembers[i];
      handleNewMember(localMember, mergeKind);
      mergedMembers[mergedMemberCount++] = localMember;
      i++;
    }
    while (j < superMembers.length) {
      final Declaration superMember = superMembers[j];
      handleInheritance(cls, superMember, mergeKind);
      mergedMembers[mergedMemberCount++] = superMember;
      j++;
    }
    return mergedMembers..length = mergedMemberCount;
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
}
