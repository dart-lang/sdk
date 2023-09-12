// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchyMembers;

import '../../builder/declaration_builders.dart';
import '../../builder/type_builder.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_field_builder.dart';
import '../../source/source_procedure_builder.dart';
import 'class_member.dart';
import 'delayed.dart';
import 'hierarchy_builder.dart';
import 'hierarchy_node.dart';
import 'members_node.dart';

class ClassMembersBuilder implements ClassHierarchyMembers {
  final ClassHierarchyBuilder hierarchyBuilder;

  final Map<Class, ClassMembersNode> nodes = <Class, ClassMembersNode>{};

  final List<DelayedTypeComputation> _delayedTypeComputations =
      <DelayedTypeComputation>[];

  final List<DelayedCheck> _delayedChecks = <DelayedCheck>[];

  final List<ClassMember> _delayedMemberComputations = <ClassMember>[];

  ClassMembersBuilder(this.hierarchyBuilder);

  void clear() {
    nodes.clear();
    _delayedChecks.clear();
    _delayedTypeComputations.clear();
    _delayedMemberComputations.clear();
  }

  void registerDelayedTypeComputation(DelayedTypeComputation computation) {
    _delayedTypeComputations.add(computation);
  }

  void registerOverrideCheck(SourceClassBuilder classBuilder,
      ClassMember declaredMember, Set<ClassMember> overriddenMembers) {
    _delayedChecks.add(new DelayedOverrideCheck(
        classBuilder, declaredMember, overriddenMembers));
  }

  void registerGetterSetterCheck(
      SourceClassBuilder classBuilder, ClassMember getter, ClassMember setter) {
    _delayedChecks
        .add(new DelayedGetterSetterCheck(classBuilder, getter, setter));
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

  void inferFieldType(SourceFieldBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    ClassMembersNodeBuilder.inferFieldType(
        hierarchyBuilder,
        this,
        declaredMember.classBuilder as SourceClassBuilder,
        declaredMember,
        overriddenMembers);
  }

  void inferGetterType(SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    ClassMembersNodeBuilder.inferGetterType(
        hierarchyBuilder,
        this,
        declaredMember.classBuilder as SourceClassBuilder,
        declaredMember,
        overriddenMembers);
  }

  void inferSetterType(SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    ClassMembersNodeBuilder.inferSetterType(
        hierarchyBuilder,
        this,
        declaredMember.classBuilder as SourceClassBuilder,
        declaredMember,
        overriddenMembers);
  }

  void inferMethodType(SourceProcedureBuilder declaredMember,
      Iterable<ClassMember> overriddenMembers) {
    ClassMembersNodeBuilder.inferMethodType(
        hierarchyBuilder,
        this,
        declaredMember.classBuilder as SourceClassBuilder,
        declaredMember,
        overriddenMembers);
  }

  ClassMembersNode getNodeFromClassBuilder(ClassBuilder classBuilder) {
    return nodes[classBuilder.cls] ??= new ClassMembersNodeBuilder(
            this, hierarchyBuilder.getNodeFromClassBuilder(classBuilder))
        .build();
  }

  ClassMembersNode? getNodeFromTypeBuilder(TypeBuilder type) {
    ClassBuilder? cls = getClass(type);
    return cls == null ? null : getNodeFromClassBuilder(cls);
  }

  ClassMembersNode getNodeFromClass(Class cls) {
    return nodes[cls] ??
        getNodeFromClassBuilder(
            hierarchyBuilder.loader.computeClassBuilderFromTargetClass(cls));
  }

  @override
  Member? getInterfaceMember(Class cls, Name name, {bool setter = false}) {
    return getNodeFromClass(cls)
        .getInterfaceMember(name, setter)
        ?.getMember(this);
  }

  ClassMember? getInterfaceClassMember(Class cls, Name name,
      {bool setter = false}) {
    return getNodeFromClass(cls).getInterfaceMember(name, setter);
  }

  @override
  Member? getDispatchTarget(Class cls, Name name, {bool setter = false}) {
    return getNodeFromClass(cls)
        .getDispatchTarget(name, setter)
        ?.getMember(this);
  }

  ClassMember? getDispatchClassMember(Class cls, Name name,
      {bool setter = false}) {
    return getNodeFromClass(cls).getDispatchTarget(name, setter);
  }

  static ClassMembersBuilder build(
      ClassHierarchyBuilder hierarchyBuilder, List<ClassBuilder> classes) {
    ClassMembersBuilder membersBuilder =
        new ClassMembersBuilder(hierarchyBuilder);
    for (int i = 0; i < classes.length; i++) {
      ClassBuilder classBuilder = classes[i];
      if (!classBuilder.isPatch) {
        membersBuilder.nodes[classBuilder.cls] = new ClassMembersNodeBuilder(
                membersBuilder,
                hierarchyBuilder.getNodeFromClassBuilder(classBuilder))
            .build();
      } else {
        // TODO(ahe): Merge the injected members of patch into the hierarchy
        // node of `cls.origin`.
      }
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
