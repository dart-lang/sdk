// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as Math;

import '../common.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../util/enumset.dart';
import 'call_structure.dart';

abstract class AbstractUsage<T> {
  final EnumSet<T> _pendingUse;

  AbstractUsage.cloned(this._pendingUse);

  AbstractUsage() : this._pendingUse = new EnumSet<T>() {
    _pendingUse.addAll(_originalUse);
  }

  /// Returns the uses of [entity] that have been registered.
  EnumSet<T> get _appliedUse => _originalUse.minus(_pendingUse);

  EnumSet<T> get _originalUse;

  /// `true` if the [_appliedUse] is non-empty.
  bool get hasUse => _appliedUse.isNotEmpty;

  /// Returns `true` if [other] has the same original and pending usage as this.
  bool hasSameUsage(AbstractUsage<T> other) {
    if (identical(this, other)) return true;
    return _originalUse.value == other._originalUse.value &&
        _pendingUse.value == other._pendingUse.value;
  }
}

/// Registry for the observed use of a member [entity] in the open world.
abstract class MemberUsage extends AbstractUsage<MemberUse> {
  final MemberEntity entity;

  MemberUsage.internal(this.entity) : super();

  MemberUsage.cloned(this.entity, EnumSet<MemberUse> pendingUse)
      : super.cloned(pendingUse);

  factory MemberUsage(MemberEntity member, {bool trackParameters: false}) {
    if (member.isField) {
      if (member.isAssignable) {
        return new FieldUsage(member);
      } else {
        return new FinalFieldUsage(member);
      }
    } else if (member.isGetter) {
      return new GetterUsage(member);
    } else if (member.isSetter) {
      return new SetterUsage(member);
    } else if (member.isConstructor) {
      if (trackParameters) {
        return new ParameterTrackingConstructorUsage(member);
      } else {
        return new ConstructorUsage(member);
      }
    } else if (member.isConstructor) {
      if (trackParameters) {
        return new ParameterTrackingConstructorUsage(member);
      } else {
        return new ConstructorUsage(member);
      }
    } else {
      assert(member is FunctionEntity,
          failedAt(member, "Unexpected member: $member"));
      if (trackParameters) {
        return new ParameterTrackingFunctionUsage(member);
      } else {
        return new FunctionUsage(member);
      }
    }
  }

  /// `true` if [entity] has been initialized.
  bool get hasInit => true;

  Iterable<ConstantValue> get initialConstants => null;

  /// `true` if [entity] has been read as a value. For a field this is a normal
  /// read access, for a function this is a closurization.
  bool get hasRead => false;

  /// `true` if a value has been written to [entity].
  bool get hasWrite => false;

  /// `true` if an invocation has been performed on the value [entity]. For a
  /// function this is a normal invocation, for a field this is a read access
  /// followed by an invocation of the function-like value.
  bool get hasInvoke => false;

  /// `true` if all parameters are provided in invocations of [entity].
  ///
  /// For method or constructors with no optional arguments this is the same
  /// as [hasInvoke] but for method or constructors with optional arguments some
  /// parameters may have been provided in any invocation in which case
  /// [isFullyInvoked] is `false`.
  bool get isFullyInvoked => hasInvoke;

  /// Returns the [ParameterStructure] corresponding to the parameters that are
  /// used in invocations of [entity]. For a field, getter or setter this is
  /// always `null`.
  ParameterStructure get invokedParameters => null;

  /// `true` if [entity] has further normal use. For a field this means that
  /// it hasn't been read from or written to. For a function this means that it
  /// hasn't been invoked or, when parameter usage is tracked, that some
  /// parameters haven't been provided in any invocation.
  bool get hasPendingNormalUse => _pendingUse.contains(MemberUse.NORMAL);

  /// `true` if [entity] hasn't been closurized. This is only used for
  /// functions.
  bool get hasPendingClosurizationUse => false;

  /// `true` if [entity] has been used in all the ways possible.
  bool get fullyUsed;

  /// Registers the [entity] has been initialized and returns the new
  /// [MemberUse]s that it caused.
  ///
  /// For a field this is the initial write access, for a function this is a
  /// no-op.
  EnumSet<MemberUse> init() => MemberUses.NONE;

  /// Registers the [entity] has been initialized with [constant] and returns
  /// the new [MemberUse]s that it caused.
  ///
  /// For a field this is the initial write access, for a function this is a
  /// no-op.
  EnumSet<MemberUse> constantInit(ConstantValue constant) => MemberUses.NONE;

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
  EnumSet<MemberUse> invoke(CallStructure callStructure) => MemberUses.NONE;

  /// Registers all possible uses of [entity] and returns the new [MemberUse]s
  /// that it caused.
  EnumSet<MemberUse> fullyUse() => MemberUses.NONE;

  @override
  EnumSet<MemberUse> get _originalUse => MemberUses.NORMAL_ONLY;

  @override
  int get hashCode => entity.hashCode;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! MemberUsage) return false;
    return entity == other.entity;
  }

  MemberUsage clone();

  bool dataEquals(MemberUsage other) {
    assert(entity == other.entity);
    return hasInit == other.hasInit &&
        hasRead == other.hasRead &&
        hasInvoke == other.hasInvoke &&
        hasWrite == other.hasWrite &&
        hasPendingClosurizationUse == other.hasPendingClosurizationUse &&
        hasPendingNormalUse == other.hasPendingNormalUse &&
        fullyUsed == other.fullyUsed &&
        isFullyInvoked == other.isFullyInvoked &&
        _pendingUse == other._pendingUse &&
        _appliedUse == other._appliedUse;
  }

  @override
  String toString() => '$entity:${_appliedUse.iterable(MemberUse.values)}';
}

class FieldUsage extends MemberUsage {
  @override
  bool hasInit;
  @override
  bool hasRead;
  @override
  bool hasWrite;

  List<ConstantValue> _initialConstants;

  FieldUsage.cloned(FieldEntity field, EnumSet<MemberUse> pendingUse,
      {this.hasInit, this.hasRead, this.hasWrite})
      : super.cloned(field, pendingUse);

  FieldUsage(FieldEntity field)
      : hasInit = false,
        hasRead = false,
        hasWrite = false,
        super.internal(field);

  @override
  Iterable<ConstantValue> get initialConstants => _initialConstants ?? const [];

  @override
  bool get hasPendingNormalUse => !fullyUsed;

  @override
  bool get fullyUsed => hasInit && hasRead && hasWrite;

  @override
  EnumSet<MemberUse> init() {
    if (hasInit) {
      return MemberUses.NONE;
    }
    hasInit = true;
    EnumSet<MemberUse> result = _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
    if (!fullyUsed) {
      result = result.union(MemberUses.PARTIAL_USE_ONLY);
    }
    return result;
  }

  @override
  EnumSet<MemberUse> constantInit(ConstantValue constant) {
    _initialConstants ??= [];
    _initialConstants.add(constant);
    return init();
  }

  @override
  EnumSet<MemberUse> read() {
    if (hasRead) {
      return MemberUses.NONE;
    }
    hasRead = true;
    EnumSet<MemberUse> result = _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
    if (!fullyUsed) {
      result = result.union(MemberUses.PARTIAL_USE_ONLY);
    }
    return result;
  }

  @override
  EnumSet<MemberUse> write() {
    if (hasWrite) {
      return MemberUses.NONE;
    }
    hasWrite = true;
    EnumSet<MemberUse> result = _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
    if (!fullyUsed) {
      result = result.union(MemberUses.PARTIAL_USE_ONLY);
    }
    return result;
  }

  @override
  EnumSet<MemberUse> invoke(CallStructure callStructure) => read();

  @override
  EnumSet<MemberUse> fullyUse() {
    if (fullyUsed) {
      return MemberUses.NONE;
    }
    hasInit = hasRead = hasWrite = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  MemberUsage clone() {
    return new FieldUsage.cloned(entity, _pendingUse.clone(),
        hasInit: hasInit, hasRead: hasRead, hasWrite: hasWrite);
  }

  @override
  String toString() => 'FieldUsage($entity,hasInit=$hasInit,hasRead=$hasRead,'
      'hasWrite=$hasWrite,pendingUse=${_pendingUse.iterable(MemberUse.values)},'
      'initialConstants=${initialConstants.map((c) => c.toStructuredText())})';
}

class FinalFieldUsage extends MemberUsage {
  @override
  bool hasInit;
  @override
  bool hasRead;

  List<ConstantValue> _initialConstants;

  FinalFieldUsage.cloned(FieldEntity field, EnumSet<MemberUse> pendingUse,
      {this.hasInit, this.hasRead})
      : super.cloned(field, pendingUse);

  FinalFieldUsage(FieldEntity field)
      : this.hasInit = false,
        this.hasRead = false,
        super.internal(field);

  @override
  Iterable<ConstantValue> get initialConstants => _initialConstants ?? const [];

  @override
  bool get hasPendingNormalUse => !fullyUsed;

  @override
  bool get fullyUsed => hasInit && hasRead;

  @override
  EnumSet<MemberUse> init() {
    if (hasInit) {
      return MemberUses.NONE;
    }
    hasInit = true;
    EnumSet<MemberUse> result = _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
    if (!fullyUsed) {
      result = result.union(MemberUses.PARTIAL_USE_ONLY);
    }
    return result;
  }

  @override
  EnumSet<MemberUse> constantInit(ConstantValue constant) {
    _initialConstants ??= [];
    _initialConstants.add(constant);
    return init();
  }

  @override
  EnumSet<MemberUse> read() {
    if (hasRead) {
      return MemberUses.NONE;
    }
    hasRead = true;
    EnumSet<MemberUse> result = _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
    if (!fullyUsed) {
      result = result.union(MemberUses.PARTIAL_USE_ONLY);
    }
    return result;
  }

  @override
  EnumSet<MemberUse> invoke(CallStructure callStructure) => read();

  @override
  EnumSet<MemberUse> fullyUse() {
    if (fullyUsed) {
      return MemberUses.NONE;
    }
    hasInit = hasRead = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  MemberUsage clone() {
    return new FinalFieldUsage.cloned(entity, _pendingUse.clone(),
        hasInit: hasInit, hasRead: hasRead);
  }

  @override
  String toString() => 'FinalFieldUsage($entity,hasInit=$hasInit,'
      'hasRead=$hasRead,pendingUse=${_pendingUse.iterable(MemberUse.values)},'
      'initialConstants=${initialConstants.map((c) => c.toStructuredText())})';
}

class FunctionUsage extends MemberUsage {
  @override
  bool hasInvoke;
  @override
  bool hasRead;

  FunctionUsage.cloned(FunctionEntity function, EnumSet<MemberUse> pendingUse,
      {this.hasInvoke, this.hasRead})
      : super.cloned(function, pendingUse);

  FunctionUsage(FunctionEntity function)
      : this.hasInvoke = false,
        this.hasRead = false,
        super.internal(function);

  @override
  FunctionEntity get entity => super.entity;

  @override
  EnumSet<MemberUse> get _originalUse =>
      entity.isInstanceMember ? MemberUses.ALL_INSTANCE : MemberUses.ALL_STATIC;

  @override
  bool get hasPendingClosurizationUse => entity.isInstanceMember
      ? _pendingUse.contains(MemberUse.CLOSURIZE_INSTANCE)
      : _pendingUse.contains(MemberUse.CLOSURIZE_STATIC);

  @override
  EnumSet<MemberUse> read() => fullyUse();

  @override
  EnumSet<MemberUse> invoke(CallStructure callStructure) {
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
      return _pendingUse.removeAll(entity.isInstanceMember
          ? MemberUses.CLOSURIZE_INSTANCE_ONLY
          : MemberUses.CLOSURIZE_STATIC_ONLY);
    } else if (hasRead) {
      hasInvoke = true;
      return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
    } else {
      hasRead = hasInvoke = true;
      return _pendingUse.removeAll(entity.isInstanceMember
          ? MemberUses.ALL_INSTANCE
          : MemberUses.ALL_STATIC);
    }
  }

  @override
  bool get fullyUsed => hasInvoke && hasRead;

  @override
  ParameterStructure get invokedParameters =>
      hasInvoke ? entity.parameterStructure : null;

  @override
  MemberUsage clone() {
    return new FunctionUsage.cloned(entity, _pendingUse.clone(),
        hasInvoke: hasInvoke, hasRead: hasRead);
  }
}

class ParameterTrackingFunctionUsage extends MemberUsage {
  @override
  bool hasRead;

  final ParameterUsage _parameterUsage;

  ParameterTrackingFunctionUsage.cloned(FunctionEntity function,
      this._parameterUsage, EnumSet<MemberUse> pendingUse,
      {this.hasRead})
      : super.cloned(function, pendingUse);

  ParameterTrackingFunctionUsage(FunctionEntity function)
      : hasRead = false,
        _parameterUsage = new ParameterUsage(function.parameterStructure),
        super.internal(function);

  @override
  bool get hasInvoke => _parameterUsage.hasInvoke;

  @override
  bool get hasPendingClosurizationUse => entity.isInstanceMember
      ? _pendingUse.contains(MemberUse.CLOSURIZE_INSTANCE)
      : _pendingUse.contains(MemberUse.CLOSURIZE_STATIC);

  @override
  EnumSet<MemberUse> get _originalUse =>
      entity.isInstanceMember ? MemberUses.ALL_INSTANCE : MemberUses.ALL_STATIC;

  @override
  EnumSet<MemberUse> read() => fullyUse();

  @override
  EnumSet<MemberUse> invoke(CallStructure callStructure) {
    if (_parameterUsage.isFullyUsed) {
      return MemberUses.NONE;
    }
    bool alreadyHasInvoke = hasInvoke;
    bool hasPartialChange = _parameterUsage.invoke(callStructure);
    EnumSet<MemberUse> result;
    if (alreadyHasInvoke) {
      result = MemberUses.NONE;
    } else {
      result = _pendingUse
          .removeAll(hasRead ? MemberUses.NONE : MemberUses.NORMAL_ONLY);
    }
    return hasPartialChange
        ? result.union(MemberUses.PARTIAL_USE_ONLY)
        : result;
  }

  @override
  EnumSet<MemberUse> fullyUse() {
    bool alreadyHasInvoke = hasInvoke;
    _parameterUsage.fullyUse();
    if (alreadyHasInvoke) {
      if (hasRead) {
        return MemberUses.NONE;
      }
      hasRead = true;
      return _pendingUse.removeAll(entity.isInstanceMember
          ? MemberUses.CLOSURIZE_INSTANCE_ONLY
          : MemberUses.CLOSURIZE_STATIC_ONLY);
    } else if (hasRead) {
      return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
    } else {
      hasRead = true;
      return _pendingUse.removeAll(entity.isInstanceMember
          ? MemberUses.ALL_INSTANCE
          : MemberUses.ALL_STATIC);
    }
  }

  @override
  bool get hasPendingNormalUse => !isFullyInvoked;

  @override
  bool get isFullyInvoked => _parameterUsage.isFullyUsed;

  @override
  bool get fullyUsed => isFullyInvoked && hasRead;

  @override
  ParameterStructure get invokedParameters => _parameterUsage.invokedParameters;

  @override
  MemberUsage clone() {
    return new ParameterTrackingFunctionUsage.cloned(
        entity, _parameterUsage.clone(), _pendingUse.clone(),
        hasRead: hasRead);
  }
}

class GetterUsage extends MemberUsage {
  @override
  bool hasRead;

  GetterUsage.cloned(FunctionEntity getter, EnumSet<MemberUse> pendingUse,
      {this.hasRead})
      : super.cloned(getter, pendingUse);

  GetterUsage(FunctionEntity getter)
      : hasRead = false,
        super.internal(getter);

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
  EnumSet<MemberUse> invoke(CallStructure callStructure) => read();

  @override
  EnumSet<MemberUse> fullyUse() => read();

  @override
  MemberUsage clone() {
    return new GetterUsage.cloned(entity, _pendingUse.clone(),
        hasRead: hasRead);
  }
}

class SetterUsage extends MemberUsage {
  @override
  bool hasWrite;

  SetterUsage.cloned(FunctionEntity setter, EnumSet<MemberUse> pendingUse,
      {this.hasWrite})
      : super.cloned(setter, pendingUse);

  SetterUsage(FunctionEntity setter)
      : hasWrite = false,
        super.internal(setter);

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

  @override
  MemberUsage clone() {
    return new SetterUsage.cloned(entity, _pendingUse.clone(),
        hasWrite: hasWrite);
  }
}

class ConstructorUsage extends MemberUsage {
  @override
  bool hasInvoke;

  ConstructorUsage.cloned(
      ConstructorEntity constructor, EnumSet<MemberUse> pendingUse,
      {this.hasInvoke})
      : super.cloned(constructor, pendingUse);

  ConstructorUsage(ConstructorEntity constructor)
      : hasInvoke = false,
        super.internal(constructor);

  @override
  ConstructorEntity get entity => super.entity;

  @override
  EnumSet<MemberUse> get _originalUse => MemberUses.NORMAL_ONLY;

  @override
  EnumSet<MemberUse> invoke(CallStructure callStructure) {
    if (hasInvoke) {
      return MemberUses.NONE;
    }
    hasInvoke = true;
    return _pendingUse
        .removeAll(hasRead ? MemberUses.NONE : MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> fullyUse() =>
      invoke(entity.parameterStructure.callStructure);

  @override
  bool get fullyUsed => hasInvoke;

  @override
  ParameterStructure get invokedParameters =>
      hasInvoke ? entity.parameterStructure : null;

  @override
  MemberUsage clone() {
    return new ConstructorUsage.cloned(entity, _pendingUse.clone(),
        hasInvoke: hasInvoke);
  }
}

class ParameterTrackingConstructorUsage extends MemberUsage {
  final ParameterUsage _parameterUsage;

  ParameterTrackingConstructorUsage.cloned(ConstructorEntity constructor,
      this._parameterUsage, EnumSet<MemberUse> pendingUse)
      : super.cloned(constructor, pendingUse);

  ParameterTrackingConstructorUsage(ConstructorEntity constructor)
      : _parameterUsage = new ParameterUsage(constructor.parameterStructure),
        super.internal(constructor);

  @override
  ConstructorEntity get entity => super.entity;

  @override
  EnumSet<MemberUse> get _originalUse => MemberUses.NORMAL_ONLY;

  @override
  EnumSet<MemberUse> invoke(CallStructure callStructure) {
    if (isFullyInvoked) {
      return MemberUses.NONE;
    }
    bool alreadyHasInvoke = hasInvoke;
    bool hasPartialChange = _parameterUsage.invoke(callStructure);
    EnumSet<MemberUse> result;
    if (alreadyHasInvoke) {
      result = MemberUses.NONE;
    } else {
      result = _pendingUse
          .removeAll(hasRead ? MemberUses.NONE : MemberUses.NORMAL_ONLY);
    }
    return hasPartialChange
        ? result.union(MemberUses.PARTIAL_USE_ONLY)
        : result;
  }

  @override
  EnumSet<MemberUse> fullyUse() =>
      invoke(entity.parameterStructure.callStructure);

  @override
  bool get hasInvoke => _parameterUsage.hasInvoke;

  @override
  bool get fullyUsed => _parameterUsage.isFullyUsed;

  @override
  bool get hasPendingNormalUse => !isFullyInvoked;

  @override
  bool get isFullyInvoked => _parameterUsage.isFullyUsed;

  @override
  ParameterStructure get invokedParameters => _parameterUsage.invokedParameters;

  @override
  MemberUsage clone() {
    return new ParameterTrackingConstructorUsage.cloned(
        entity, _parameterUsage.clone(), _pendingUse.clone());
  }
}

/// Enum class for the possible kind of use of [MemberEntity] objects.
enum MemberUse {
  /// Read or write of a field, or invocation of a method.
  NORMAL,

  /// Tear-off of an instance method.
  CLOSURIZE_INSTANCE,

  /// Tear-off of a static method.
  CLOSURIZE_STATIC,

  /// Invocation that provides previously unprovided optional parameters.
  ///
  /// This is used to check that no partial use is missed by the enqueuer, as
  /// asserted through the `Enqueuery.checkEnqueuerConsistency` method.
  PARTIAL_USE,
}

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
  static const EnumSet<MemberUse> PARTIAL_USE_ONLY =
      const EnumSet<MemberUse>.fixed(8);
}

typedef void MemberUsedCallback(MemberEntity member, EnumSet<MemberUse> useSet);

/// Registry for the observed use of a class [entity] in the open world.
// TODO(johnniwinther): Merge this with [InstantiationInfo].
class ClassUsage extends AbstractUsage<ClassUse> {
  bool isInstantiated = false;
  bool isImplemented = false;

  final ClassEntity cls;

  ClassUsage(this.cls) : super();

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

  @override
  String toString() => '$cls:${_appliedUse.iterable(ClassUse.values)}';
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

/// Object used for tracking parameter use in constructor and method
/// invocations.
class ParameterUsage {
  /// The original parameter structure of the method or constructor.
  final ParameterStructure _parameterStructure;

  /// `true` if the method or constructor has at least one invocation.
  bool _hasInvoke;

  /// The maximum number of (optional) positional parameters provided in
  /// invocations of the method or constructor.
  ///
  /// If all positional parameters having been provided this is set to `null`.
  int _providedPositionalParameters;

  /// `true` if all type parameters have been provided in at least one
  /// invocation of the method or constructor.
  bool _areAllTypeParametersProvided;

  /// The set of named parameters that have not yet been provided in any
  /// invocation of the method or constructor.
  ///
  /// If all named parameters have been provided this is set to `null`.
  Set<String> _unprovidedNamedParameters;

  ParameterUsage(this._parameterStructure) {
    _hasInvoke = false;
    _areAllTypeParametersProvided = _parameterStructure.typeParameters == 0;
    _providedPositionalParameters = _parameterStructure.positionalParameters ==
            _parameterStructure.requiredParameters
        ? null
        : 0;
    if (!_parameterStructure.namedParameters.isEmpty) {
      _unprovidedNamedParameters =
          new Set<String>.from(_parameterStructure.namedParameters);
    }
  }

  ParameterUsage.cloned(this._parameterStructure,
      {bool hasInvoke,
      int providedPositionalParameters,
      bool areAllTypeParametersProvided,
      Set<String> unprovidedNamedParameters})
      : _hasInvoke = hasInvoke,
        _providedPositionalParameters = providedPositionalParameters,
        _areAllTypeParametersProvided = areAllTypeParametersProvided,
        _unprovidedNamedParameters = unprovidedNamedParameters;

  bool invoke(CallStructure callStructure) {
    if (isFullyUsed) return false;
    _hasInvoke = true;
    bool changed = false;
    if (_providedPositionalParameters != null) {
      int newProvidedPositionalParameters = Math.max(
          _providedPositionalParameters, callStructure.positionalArgumentCount);
      changed |=
          newProvidedPositionalParameters != _providedPositionalParameters;
      _providedPositionalParameters = newProvidedPositionalParameters;
      if (_providedPositionalParameters >=
          _parameterStructure.positionalParameters) {
        _providedPositionalParameters = null;
      }
    }
    if (_unprovidedNamedParameters != null &&
        callStructure.namedArguments.isNotEmpty) {
      int _providedNamedParametersCount = _unprovidedNamedParameters.length;
      _unprovidedNamedParameters.removeAll(callStructure.namedArguments);
      changed |=
          _providedNamedParametersCount != _unprovidedNamedParameters.length;
      if (_unprovidedNamedParameters.isEmpty) {
        _unprovidedNamedParameters = null;
      }
    }
    if (!_areAllTypeParametersProvided && callStructure.typeArgumentCount > 0) {
      _areAllTypeParametersProvided = true;
      changed = true;
    }
    return changed;
  }

  bool get hasInvoke => _hasInvoke;

  bool get isFullyUsed =>
      _hasInvoke &&
      _providedPositionalParameters == null &&
      _unprovidedNamedParameters == null &&
      _areAllTypeParametersProvided;

  void fullyUse() {
    _hasInvoke = true;
    _providedPositionalParameters = null;
    _unprovidedNamedParameters = null;
    _areAllTypeParametersProvided = true;
  }

  ParameterStructure get invokedParameters {
    if (!_hasInvoke) return null;
    if (isFullyUsed) return _parameterStructure;
    return new ParameterStructure(
        _parameterStructure.requiredParameters,
        _providedPositionalParameters ??
            _parameterStructure.positionalParameters,
        _unprovidedNamedParameters == null
            ? _parameterStructure.namedParameters
            : _parameterStructure.namedParameters
                .where((n) => !_unprovidedNamedParameters.contains(n))
                .toList(),
        _areAllTypeParametersProvided ? _parameterStructure.typeParameters : 0);
  }

  ParameterUsage clone() {
    return new ParameterUsage.cloned(_parameterStructure,
        hasInvoke: _hasInvoke,
        providedPositionalParameters: _providedPositionalParameters,
        areAllTypeParametersProvided: _areAllTypeParametersProvided,
        unprovidedNamedParameters: _unprovidedNamedParameters?.toSet());
  }
}
