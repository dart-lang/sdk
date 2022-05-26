// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../constants/values.dart' show ConstantValue;
import '../elements/entities.dart';

/// [EntityData] is the base class of wrapped [Entity] objects. Each
/// [EntityData] child knows how to use an [EntityDataCollector] to collect
/// [EntityDataInfo]. [EntityData] objects are canonicalized and must be created
/// by an [EntityDataRegistry].
abstract class EntityData<T> {
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

  ClassEntityData(ClassEntity entity) : super(entity);
}

class ClassTypeEntityData extends EntityData<ClassEntity> {
  @override
  void accept(EntityDataVisitor visitor) {
    visitor.visitClassTypeEntityData(entity);
  }

  ClassTypeEntityData(ClassEntity entity) : super(entity);
}

class MemberEntityData extends EntityData<MemberEntity> {
  @override
  void accept(EntityDataVisitor visitor) {
    visitor.visitMemberEntityData(entity);
  }

  MemberEntityData(MemberEntity entity) : super(entity);
}

class LocalFunctionEntityData extends EntityData<Local> {
  @override
  void accept(EntityDataVisitor) {}

  // Note: local functions are not updated recursively because the
  // dependencies are already visited as dependencies of the enclosing member.
  @override
  bool get needsRecursiveUpdate => false;

  LocalFunctionEntityData(Local entity) : super(entity);
}

class ConstantEntityData extends EntityData<ConstantValue> {
  @override
  void accept(EntityDataVisitor visitor) {
    visitor.visitConstantEntityData(entity);
  }

  ConstantEntityData(ConstantValue entity) : super(entity);
}

/// A registry used to canonicalize [EntityData].
class EntityDataRegistry {
  /// Map of [Entity] / [ConstantValue] to [EntityData], used by all non
  /// [ClassTypeEntityData].
  final Map<Object, EntityData> _nonClassTypeData = {};

  /// Map of [ClassEntity] to [EntityData], used by [ClassTypeEntityData].
  final Map<ClassEntity, ClassTypeEntityData> _classTypeData = {};

  EntityData createClassEntityData(ClassEntity cls) {
    return _nonClassTypeData[cls] ??= ClassEntityData(cls);
  }

  EntityData createClassTypeEntityData(ClassEntity cls) {
    return _classTypeData[cls] ??= ClassTypeEntityData(cls);
  }

  EntityData createConstantEntityData(ConstantValue constant) {
    return _nonClassTypeData[constant] ??= ConstantEntityData(constant);
  }

  EntityData createLocalFunctionEntityData(Local localFunction) {
    return _nonClassTypeData[localFunction] ??=
        LocalFunctionEntityData(localFunction);
  }

  EntityData createMemberEntityData(MemberEntity member) {
    return _nonClassTypeData[member] ??= MemberEntityData(member);
  }
}

/// A trivial visitor to facilate interacting with [EntityData].
abstract class EntityDataVisitor {
  void visitClassEntityData(ClassEntity element);
  void visitClassTypeEntityData(ClassEntity element);
  void visitConstantEntityData(ConstantValue constant);
  void visitMemberEntityData(MemberEntity member);
}
