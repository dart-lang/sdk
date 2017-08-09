// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of world_builder;

abstract class AbstractUsage<T> {
  final EnumSet<T> _pendingUse = new EnumSet<T>();

  AbstractUsage() {
    _pendingUse.addAll(_originalUse);
  }

  /// Returns the possible uses of [entity] that have not yet been registered.
  EnumSet<T> get pendingUse => _pendingUse;

  /// Returns the uses of [entity] that have been registered.
  EnumSet<T> get appliedUse => _originalUse.minus(_pendingUse);

  EnumSet<T> get _originalUse;

  /// `true` if the [appliedUse] is non-empty.
  bool get hasUse => appliedUse.isNotEmpty;

  /// Returns `true` if [other] has the same original and pending usage as this.
  bool hasSameUsage(AbstractUsage<T> other) {
    if (identical(this, other)) return true;
    return _originalUse.value == other._originalUse.value &&
        _pendingUse.value == other._pendingUse.value;
  }
}

/// Registry for the observed use of a member [entity] in the open world.
abstract class _MemberUsage extends AbstractUsage<MemberUse> {
  // TODO(johnniwinther): Change [Entity] to [MemberEntity].
  final Entity entity;

  _MemberUsage.internal(this.entity);

  factory _MemberUsage(MemberEntity member, {bool isNative: false}) {
    if (member.isField) {
      if (member.isAssignable) {
        return new _FieldUsage(member, isNative: isNative);
      } else {
        return new _FinalFieldUsage(member, isNative: isNative);
      }
    } else if (member.isGetter) {
      return new _GetterUsage(member);
    } else if (member.isSetter) {
      return new _SetterUsage(member);
    } else {
      assert(member.isFunction, failedAt(member, "Unexpected member: $member"));
      return new _FunctionUsage(member);
    }
  }

  /// `true` if [entity] has been read as a value. For a field this is a normal
  /// read access, for a function this is a closurization.
  bool get hasRead => false;

  /// `true` if a value has been written to [entity].
  bool get hasWrite => false;

  /// `true` if an invocation has been performed on the value [entity]. For a
  /// function this is a normal invocation, for a field this is a read access
  /// followed by an invocation of the function-like value.
  bool get hasInvoke => false;

  /// `true` if [entity] has been used in all the ways possible.
  bool get fullyUsed;

  /// Registers a read of the value of [entity] and returns the new [MemberUse]s
  /// that it caused.
  ///
  /// For a field this is a normal read access, for a function this is a
  /// closurization.
  EnumSet<MemberUse> read() => MemberUses.NONE;

  /// Registers a write of a value to [entity] and returns the new [MemberUse]s
  /// that it caused.
  EnumSet<MemberUse> write() => MemberUses.NONE;

  /// Registers an invocation on the value of [entity] and returns the new
  /// [MemberUse]s that it caused.
  ///
  /// For a function this is a normal invocation, for a field this is a read
  /// access followed by an invocation of the function-like value.
  EnumSet<MemberUse> invoke() => MemberUses.NONE;

  /// Registers all possible uses of [entity] and returns the new [MemberUse]s
  /// that it caused.
  EnumSet<MemberUse> fullyUse() => MemberUses.NONE;

  @override
  EnumSet<MemberUse> get _originalUse => MemberUses.NORMAL_ONLY;

  int get hashCode => entity.hashCode;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! _MemberUsage) return false;
    return entity == other.entity;
  }

  String toString() => '$entity:${appliedUse.iterable(MemberUse.values)}';
}

class _FieldUsage extends _MemberUsage {
  bool hasRead = false;
  bool hasWrite = false;

  _FieldUsage(FieldEntity field, {bool isNative: false})
      : super.internal(field) {
    if (!isNative) {
      // All field initializers must be resolved as they could
      // have an observable side-effect (and cannot be tree-shaken
      // away).
      fullyUse();
    }
  }

  @override
  bool get fullyUsed => hasRead && hasWrite;

  @override
  EnumSet<MemberUse> read() {
    if (fullyUsed) {
      return MemberUses.NONE;
    }
    hasRead = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> write() {
    if (fullyUsed) {
      return MemberUses.NONE;
    }
    hasWrite = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> invoke() => read();

  @override
  EnumSet<MemberUse> fullyUse() {
    if (fullyUsed) {
      return MemberUses.NONE;
    }
    hasRead = hasWrite = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }
}

class _FinalFieldUsage extends _MemberUsage {
  bool hasRead = false;

  _FinalFieldUsage(FieldEntity field, {bool isNative: false})
      : super.internal(field) {
    if (!isNative) {
      // All field initializers must be resolved as they could
      // have an observable side-effect (and cannot be tree-shaken
      // away).
      read();
    }
  }

  @override
  bool get fullyUsed => hasRead;

  @override
  EnumSet<MemberUse> read() {
    if (hasRead) {
      return MemberUses.NONE;
    }
    hasRead = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> invoke() => read();

  @override
  EnumSet<MemberUse> fullyUse() => read();
}

class _FunctionUsage extends _MemberUsage {
  bool hasInvoke = false;
  bool hasRead = false;

  _FunctionUsage(FunctionEntity function) : super.internal(function);

  EnumSet<MemberUse> get _originalUse => MemberUses.ALL_INSTANCE;

  @override
  EnumSet<MemberUse> read() => fullyUse();

  @override
  EnumSet<MemberUse> invoke() {
    if (hasInvoke) {
      return MemberUses.NONE;
    }
    hasInvoke = true;
    return _pendingUse
        .removeAll(hasRead ? MemberUses.NONE : MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> fullyUse() {
    if (hasInvoke) {
      if (hasRead) {
        return MemberUses.NONE;
      }
      hasRead = true;
      return _pendingUse.removeAll(MemberUses.CLOSURIZE_INSTANCE_ONLY);
    } else if (hasRead) {
      hasInvoke = true;
      return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
    } else {
      hasRead = hasInvoke = true;
      return _pendingUse.removeAll(MemberUses.ALL_INSTANCE);
    }
  }

  @override
  bool get fullyUsed => hasInvoke && hasRead;
}

class _GetterUsage extends _MemberUsage {
  bool hasRead = false;

  _GetterUsage(FunctionEntity getter) : super.internal(getter);

  @override
  bool get fullyUsed => hasRead;

  @override
  EnumSet<MemberUse> read() {
    if (hasRead) {
      return MemberUses.NONE;
    }
    hasRead = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> invoke() => read();

  @override
  EnumSet<MemberUse> fullyUse() => read();
}

class _SetterUsage extends _MemberUsage {
  bool hasWrite = false;

  _SetterUsage(FunctionEntity setter) : super.internal(setter);

  @override
  bool get fullyUsed => hasWrite;

  @override
  EnumSet<MemberUse> write() {
    if (hasWrite) {
      return MemberUses.NONE;
    }
    hasWrite = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> fullyUse() => write();
}

/// Enum class for the possible kind of use of [MemberEntity] objects.
enum MemberUse { NORMAL, CLOSURIZE_INSTANCE, CLOSURIZE_STATIC }

/// Common [EnumSet]s used for [MemberUse].
class MemberUses {
  static const EnumSet<MemberUse> NONE = const EnumSet<MemberUse>.fixed(0);
  static const EnumSet<MemberUse> NORMAL_ONLY =
      const EnumSet<MemberUse>.fixed(1);
  static const EnumSet<MemberUse> CLOSURIZE_INSTANCE_ONLY =
      const EnumSet<MemberUse>.fixed(2);
  static const EnumSet<MemberUse> CLOSURIZE_STATIC_ONLY =
      const EnumSet<MemberUse>.fixed(4);
  static const EnumSet<MemberUse> ALL_INSTANCE =
      const EnumSet<MemberUse>.fixed(3);
  static const EnumSet<MemberUse> ALL_STATIC =
      const EnumSet<MemberUse>.fixed(5);
}

typedef void MemberUsedCallback(MemberEntity member, EnumSet<MemberUse> useSet);

/// Registry for the observed use of a class [entity] in the open world.
// TODO(johnniwinther): Merge this with [InstantiationInfo].
class _ClassUsage extends AbstractUsage<ClassUse> {
  bool isInstantiated = false;
  bool isImplemented = false;

  final ClassEntity cls;

  _ClassUsage(this.cls);

  EnumSet<ClassUse> instantiate() {
    if (isInstantiated) {
      return ClassUses.NONE;
    }
    isInstantiated = true;
    return _pendingUse.removeAll(ClassUses.INSTANTIATED_ONLY);
  }

  EnumSet<ClassUse> implement() {
    if (isImplemented) {
      return ClassUses.NONE;
    }
    isImplemented = true;
    return _pendingUse.removeAll(ClassUses.IMPLEMENTED_ONLY);
  }

  @override
  EnumSet<ClassUse> get _originalUse => ClassUses.ALL;

  String toString() => '$cls:${appliedUse.iterable(ClassUse.values)}';
}

/// Enum class for the possible kind of use of [ClassEntity] objects.
enum ClassUse { INSTANTIATED, IMPLEMENTED }

/// Common [EnumSet]s used for [ClassUse].
class ClassUses {
  static const EnumSet<ClassUse> NONE = const EnumSet<ClassUse>.fixed(0);
  static const EnumSet<ClassUse> INSTANTIATED_ONLY =
      const EnumSet<ClassUse>.fixed(1);
  static const EnumSet<ClassUse> IMPLEMENTED_ONLY =
      const EnumSet<ClassUse>.fixed(2);
  static const EnumSet<ClassUse> ALL = const EnumSet<ClassUse>.fixed(3);
}

typedef void ClassUsedCallback(ClassEntity cls, EnumSet<ClassUse> useSet);

// TODO(johnniwinther): Merge this with [_MemberUsage].
abstract class _StaticMemberUsage extends AbstractUsage<MemberUse> {
  final Entity entity;

  bool hasNormalUse = false;
  bool get hasClosurization => false;

  _StaticMemberUsage.internal(this.entity);

  EnumSet<MemberUse> normalUse() {
    if (hasNormalUse) {
      return MemberUses.NONE;
    }
    hasNormalUse = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  EnumSet<MemberUse> tearOff();

  @override
  EnumSet<MemberUse> get _originalUse => MemberUses.NORMAL_ONLY;

  String toString() => '$entity:${appliedUse.iterable(MemberUse.values)}';
}

class _GeneralStaticMemberUsage extends _StaticMemberUsage {
  _GeneralStaticMemberUsage(Entity entity) : super.internal(entity);

  EnumSet<MemberUse> tearOff() => normalUse();
}

class _StaticFunctionUsage extends _StaticMemberUsage {
  bool hasClosurization = false;

  _StaticFunctionUsage(Entity entity) : super.internal(entity);

  EnumSet<MemberUse> tearOff() {
    if (hasClosurization) {
      return MemberUses.NONE;
    }
    hasNormalUse = hasClosurization = true;
    return _pendingUse.removeAll(MemberUses.ALL_STATIC);
  }

  @override
  EnumSet<MemberUse> get _originalUse => MemberUses.ALL_STATIC;
}
