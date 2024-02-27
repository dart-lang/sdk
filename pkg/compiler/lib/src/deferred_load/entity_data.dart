// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../constants/values.dart' show ConstantValue;
import '../elements/entities.dart';

/// [EntityData] is the base class of wrapped [Entity] objects. Each
/// [EntityData] child knows how to use an [EntityDataCollector] to collect
/// [EntityDataInfo]. [EntityData] objects are canonicalized and must be created
/// by an [EntityDataRegistry].
abstract class EntityData<T extends Object> {
  final T entity;

  EntityData(this.entity);

  void accept(EntityDataVisitor visitor);

  /// Whether or not the [EntityData] needs to be updated recursively.
  bool get needsRecursiveUpdate => true;
}

class ClassEntityData extends EntityData<ClassEntity> {
  @override
  void accept(EntityDataVisitor visitor) {
    visitor.visitClassEntityData(entity);
  }

  ClassEntityData(super.entity);
}

class ClassTypeEntityData extends EntityData<ClassEntity> {
  @override
  void accept(EntityDataVisitor visitor) {
    visitor.visitClassTypeEntityData(entity);
  }

  ClassTypeEntityData(super.entity);
}

class MemberEntityData extends EntityData<MemberEntity> {
  @override
  void accept(EntityDataVisitor visitor) {
    visitor.visitMemberEntityData(entity);
  }

  MemberEntityData(super.entity);
}

class LocalFunctionEntityData extends EntityData<Local> {
  @override
  void accept(EntityDataVisitor) {}

  // Note: local functions are not updated recursively because the
  // dependencies are already visited as dependencies of the enclosing member.
  @override
  bool get needsRecursiveUpdate => false;

  LocalFunctionEntityData(super.entity);
}

class ConstantEntityData extends EntityData<ConstantValue> {
  @override
  void accept(EntityDataVisitor visitor) {
    visitor.visitConstantEntityData(entity);
  }

  ConstantEntityData(super.entity);
}

/// A registry used to canonicalize [EntityData].
class EntityDataRegistry {
  final Map<ClassEntity, ClassEntityData> _classData = {};
  final Map<ClassEntity, ClassTypeEntityData> _classTypeData = {};
  final Map<ConstantValue, ConstantEntityData> _constantData = {};
  final Map<Local, LocalFunctionEntityData> _localFunctionData = {};
  final Map<MemberEntity, MemberEntityData> _memberData = {};

  ClassEntityData createClassEntityData(ClassEntity cls) =>
      _classData[cls] ??= ClassEntityData(cls);

  ClassTypeEntityData createClassTypeEntityData(ClassEntity cls) =>
      _classTypeData[cls] ??= ClassTypeEntityData(cls);

  ConstantEntityData createConstantEntityData(ConstantValue constant) =>
      _constantData[constant] ??= ConstantEntityData(constant);

  LocalFunctionEntityData createLocalFunctionEntityData(Local localFunction) =>
      _localFunctionData[localFunction] ??=
          LocalFunctionEntityData(localFunction);

  MemberEntityData createMemberEntityData(MemberEntity member) {
    return _memberData[member] ??= MemberEntityData(member);
  }
}

/// A trivial visitor to facilitate interacting with [EntityData].
abstract class EntityDataVisitor {
  void visitClassEntityData(ClassEntity element);
  void visitClassTypeEntityData(ClassEntity element);
  void visitConstantEntityData(ConstantValue constant);
  void visitMemberEntityData(MemberEntity member);
}
