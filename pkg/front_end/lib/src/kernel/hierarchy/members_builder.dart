// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchyMembers;

import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/type_builder.dart';
import '../../source/source_class_builder.dart';
import 'class_member.dart';
import 'delayed.dart';
import 'extension_type_members.dart';
import 'hierarchy_builder.dart';
import 'members_node.dart';

class ClassMembersBuilder implements ClassHierarchyMembers {
  final ClassHierarchyBuilder hierarchyBuilder;

  final Map<Class, ClassMembersNode> classNodes = new Map.identity();

  final Map<ExtensionTypeDeclaration, ExtensionTypeMembersNode>
  extensionTypeDeclarationNodes = {};

  final List<DelayedTypeComputation> _delayedTypeComputations =
      <DelayedTypeComputation>[];

  final List<DelayedCheck> _delayedChecks = <DelayedCheck>[];

  final List<ClassMember> _delayedMemberComputations = <ClassMember>[];

  final bool _isClosureContextLoweringEnabled;

  ClassMembersBuilder(
    this.hierarchyBuilder, {
    required bool isClosureContextLoweringEnabled,
  }) : _isClosureContextLoweringEnabled = isClosureContextLoweringEnabled;

  void clear() {
    classNodes.clear();
    _delayedChecks.clear();
    _delayedTypeComputations.clear();
    _delayedMemberComputations.clear();
    extensionTypeDeclarationNodes.clear();
  }

  void registerDelayedTypeComputation(DelayedTypeComputation computation) {
    _delayedTypeComputations.add(computation);
  }

  void registerOverrideCheck(
    SourceClassBuilder classBuilder,
    ClassMember declaredMember,
    Set<ClassMember> overriddenMembers, {
    required ClassMember? localMember,
  }) {
    _delayedChecks.add(
      new DelayedOverrideCheck(
        classBuilder,
        declaredMember,
        overriddenMembers,
        localMember: localMember,
      ),
    );
  }

  void registerGetterSetterCheck(DelayedGetterSetterCheck check) {
    _delayedChecks.add(check);
  }

  void registerMemberComputation(ClassMember member) {
    _delayedMemberComputations.add(member);
  }

  List<DelayedTypeComputation> takeDelayedTypeComputations() {
    List<DelayedTypeComputation> list = _delayedTypeComputations.toList();
    _delayedTypeComputations.clear();
    return list;
  }

  List<DelayedCheck> takeDelayedChecks() {
    List<DelayedCheck> list = _delayedChecks.toList();
    _delayedChecks.clear();
    return list;
  }

  List<ClassMember> takeDelayedMemberComputations() {
    List<ClassMember> list = _delayedMemberComputations.toList();
    _delayedMemberComputations.clear();
    return list;
  }

  void inferFieldType(
    SourceClassBuilder enclosingClassBuilder,
    TypeBuilder declaredFieldType,
    Iterable<ClassMember> overriddenMembers, {
    required String name,
    required Uri fileUri,
    required int nameOffset,
    required int nameLength,
    required bool isAssignable,
    required bool isClosureContextLoweringEnabled,
  }) {
    ClassMembersNodeBuilder.inferFieldType(
      hierarchyBuilder,
      this,
      enclosingClassBuilder,
      declaredFieldType,
      overriddenMembers,
      name: name,
      fileUri: fileUri,
      nameOffset: nameOffset,
      nameLength: nameLength,
      isAssignable: isAssignable,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
  }

  void inferGetterType(
    SourceClassBuilder enclosingClassBuilder,
    TypeBuilder declaredTypeBuilder,
    Iterable<ClassMember> overriddenMembers, {
    required String name,
    required Uri fileUri,
    required int nameOffset,
    required int nameLength,
    required bool isClosureContextLoweringEnabled,
  }) {
    ClassMembersNodeBuilder.inferGetterType(
      hierarchyBuilder,
      this,
      enclosingClassBuilder,
      declaredTypeBuilder,
      overriddenMembers,
      name: name,
      fileUri: fileUri,
      nameOffset: nameOffset,
      nameLength: nameLength,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
  }

  void inferSetterType(
    SourceClassBuilder enclosingClassBuilder,
    List<FormalParameterBuilder>? formals,
    Iterable<ClassMember> overriddenMembers, {
    required String name,
    required Uri fileUri,
    required int nameOffset,
    required int nameLength,
    required bool isClosureContextLoweringEnabled,
  }) {
    ClassMembersNodeBuilder.inferSetterType(
      hierarchyBuilder,
      this,
      enclosingClassBuilder,
      formals,
      overriddenMembers,
      name: name,
      fileUri: fileUri,
      nameOffset: nameOffset,
      nameLength: nameLength,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
  }

  void inferMethodType(
    SourceClassBuilder enclosingClassBuilder,
    FunctionNode declaredFunction,
    TypeBuilder declaredReturnType,
    List<FormalParameterBuilder>? formals,
    Iterable<ClassMember> overriddenMembers, {
    required String name,
    required Uri fileUri,
    required int nameOffset,
    required int nameLength,
    required bool isClosureContextLoweringEnabled,
  }) {
    ClassMembersNodeBuilder.inferMethodType(
      hierarchyBuilder,
      this,
      enclosingClassBuilder,
      declaredFunction,
      declaredReturnType,
      formals,
      overriddenMembers,
      name: name,
      fileUri: fileUri,
      nameOffset: nameOffset,
      nameLength: nameLength,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
  }

  ClassMembersNode getNodeFromClassBuilder(ClassBuilder classBuilder) {
    return classNodes[classBuilder.cls] ??= new ClassMembersNodeBuilder(
      this,
      hierarchyBuilder.getNodeFromClassBuilder(classBuilder),
      isClosureContextLoweringEnabled: _isClosureContextLoweringEnabled,
    ).build();
  }

  ExtensionTypeMembersNode getNodeFromExtensionTypeDeclarationBuilder(
    ExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder,
  ) {
    return extensionTypeDeclarationNodes[extensionTypeDeclarationBuilder
        .extensionTypeDeclaration] ??= new ExtensionTypeMembersNodeBuilder(
      this,
      hierarchyBuilder.getNodeFromExtensionTypeDeclarationBuilder(
        extensionTypeDeclarationBuilder,
      ),
      isClosureContextLoweringEnabled: _isClosureContextLoweringEnabled,
    ).build();
  }

  ClassMembersNode getNodeFromClass(Class cls) {
    return classNodes[cls] ??
        getNodeFromClassBuilder(
          hierarchyBuilder.loader.computeClassBuilderFromTargetClass(cls),
        );
  }

  ExtensionTypeMembersNode getNodeFromExtensionTypeDeclaration(
    ExtensionTypeDeclaration extensionTypeDeclaration,
  ) {
    return extensionTypeDeclarationNodes[extensionTypeDeclaration] ??
        getNodeFromExtensionTypeDeclarationBuilder(
          hierarchyBuilder.loader
              .computeExtensionTypeBuilderFromTargetExtensionType(
                extensionTypeDeclaration,
              ),
        );
  }

  @override
  Member? getInterfaceMember(Class cls, Name name, {bool setter = false}) {
    return getNodeFromClass(
      cls,
    ).getInterfaceMember(name, setter)?.getMember(this);
  }

  ClassMember? getExtensionTypeClassMember(
    ExtensionTypeDeclaration extensionTypeDeclaration,
    Name name, {
    bool setter = false,
  }) {
    return getNodeFromExtensionTypeDeclaration(
      extensionTypeDeclaration,
    ).getMember(name, setter);
  }

  ClassMember? getExtensionTypeStaticClassMember(
    ExtensionTypeDeclaration extensionTypeDeclaration,
    Name name, {
    bool setter = false,
  }) {
    return getNodeFromExtensionTypeDeclaration(
      extensionTypeDeclaration,
    ).getStaticMember(name, setter);
  }

  @override
  Member? getDispatchTarget(Class cls, Name name, {bool setter = false}) {
    return getNodeFromClass(
      cls,
    ).getDispatchTarget(name, setter)?.getMember(this);
  }

  ClassMember? getDispatchClassMember(
    Class cls,
    Name name, {
    bool setter = false,
  }) {
    return getNodeFromClass(cls).getDispatchTarget(name, setter);
  }

  Member? getStaticMember(Class cls, Name name, {bool setter = false}) {
    return getNodeFromClass(cls).getStaticMember(name, setter)?.getMember(this);
  }

  static ClassMembersBuilder build(
    ClassHierarchyBuilder hierarchyBuilder,
    List<ClassBuilder> classes,
    List<ExtensionTypeDeclarationBuilder> extensionTypeDeclarations, {
    required bool isClosureContextLoweringEnabled,
  }) {
    ClassMembersBuilder membersBuilder = new ClassMembersBuilder(
      hierarchyBuilder,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
    for (ClassBuilder classBuilder in classes) {
      membersBuilder.getNodeFromClassBuilder(classBuilder);
    }
    for (ExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder
        in extensionTypeDeclarations) {
      membersBuilder.getNodeFromExtensionTypeDeclarationBuilder(
        extensionTypeDeclarationBuilder,
      );
    }
    return membersBuilder;
  }

  void computeTypes() {
    List<DelayedTypeComputation> typeComputations =
        takeDelayedTypeComputations();
    for (int i = 0; i < typeComputations.length; i++) {
      typeComputations[i].compute(this);
    }
  }
}

int compareNamedParameters(VariableDeclaration a, VariableDeclaration b) {
  return a.name!.compareTo(b.name!);
}
