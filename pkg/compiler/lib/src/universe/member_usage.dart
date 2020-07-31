// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as Math;

import '../common.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../js_model/closure.dart';
import '../serialization/serialization.dart';
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
  /// Constant empty access set used as the potential access set for impossible
  /// accesses, for instance writing to a final field or invoking a setter.
  static const EnumSet<Access> emptySet = const EnumSet.fixed(0);

  final MemberEntity entity;

  MemberUsage.internal(this.entity) : super();

  MemberUsage.cloned(this.entity, EnumSet<MemberUse> pendingUse)
      : super.cloned(pendingUse);

  factory MemberUsage(MemberEntity member, {MemberAccess potentialAccess}) {
    /// Create the set of potential accesses to [member], limited to [original]
    /// if provided.
    EnumSet<Access> createPotentialAccessSet(EnumSet<Access> original) {
      if (original != null) {
        if (original.isEmpty) return emptySet;
        return original.clone();
      }
      if (member.isTopLevel || member.isStatic || member.isConstructor) {
        // TODO(johnniwinther): Track super constructor invocations?
        return new EnumSet.fromValues([Access.staticAccess]);
      } else if (member.isInstanceMember) {
        return new EnumSet.fromValues(Access.values);
      } else {
        assert(member is JRecordField, "Unexpected member: $member");
        return new EnumSet();
      }
    }

    /// Create the set of potential read accesses to [member], limited to reads
    /// in [potentialAccess] if provided.
    EnumSet<Access> createPotentialReads() {
      return createPotentialAccessSet(potentialAccess?.reads);
    }

    /// Create the set of potential write accesses to [member], limited to
    /// writes in [potentialAccess] if provided.
    EnumSet<Access> createPotentialWrites() {
      return createPotentialAccessSet(potentialAccess?.writes);
    }

    /// Create the set of potential invocation accesses to [member], limited to
    /// invocations in [potentialAccess] if provided.
    EnumSet<Access> createPotentialInvokes() {
      return createPotentialAccessSet(potentialAccess?.invokes);
    }

    if (member.isField) {
      if (member.isAssignable) {
        return new FieldUsage(member,
            potentialReads: createPotentialReads(),
            potentialWrites: createPotentialWrites(),
            potentialInvokes: createPotentialInvokes());
      } else {
        return new FieldUsage(member,
            potentialReads: createPotentialReads(),
            potentialWrites: emptySet,
            potentialInvokes: createPotentialInvokes());
      }
    } else if (member.isGetter) {
      return new PropertyUsage(member,
          potentialReads: createPotentialReads(),
          potentialWrites: emptySet,
          potentialInvokes: createPotentialInvokes());
    } else if (member.isSetter) {
      return new PropertyUsage(member,
          potentialReads: emptySet,
          potentialWrites: createPotentialWrites(),
          potentialInvokes: emptySet);
    } else if (member.isConstructor) {
      return new MethodUsage(member,
          potentialReads: emptySet, potentialInvokes: createPotentialInvokes());
    } else {
      assert(member is FunctionEntity,
          failedAt(member, "Unexpected member: $member"));
      return new MethodUsage(member,
          potentialReads: createPotentialReads(),
          potentialInvokes: createPotentialInvokes());
    }
  }

  /// `true` if [entity] has been initialized.
  bool get hasInit => true;

  /// The set of constant initial values for a field.
  Iterable<ConstantValue> get initialConstants => null;

  /// `true` if [entity] has been read as a value. For a field this is a normal
  /// read access, for a function this is a closurization.
  bool get hasRead => reads.isNotEmpty;

  /// The set of potential read accesses to this member that have not yet
  /// been registered.
  EnumSet<Access> get potentialReads => const EnumSet.fixed(0);

  /// The set of registered read accesses to this member.
  EnumSet<Access> get reads => const EnumSet.fixed(0);

  /// `true` if a value has been written to [entity].
  bool get hasWrite => writes.isNotEmpty;

  /// The set of potential write accesses to this member that have not yet
  /// been registered.
  EnumSet<Access> get potentialWrites => const EnumSet.fixed(0);

  /// The set of registered write accesses to this member.
  EnumSet<Access> get writes => const EnumSet.fixed(0);

  /// `true` if an invocation has been performed on the value [entity]. For a
  /// function this is a normal invocation, for a field this is a read access
  /// followed by an invocation of the function-like value.
  bool get hasInvoke => invokes.isNotEmpty;

  /// The set of potential invocation accesses to this member that have not yet
  /// been registered.
  EnumSet<Access> get potentialInvokes => const EnumSet.fixed(0);

  /// The set of registered invocation accesses to this member.
  EnumSet<Access> get invokes => const EnumSet.fixed(0);

  /// Returns the [ParameterStructure] corresponding to the parameters that are
  /// used in invocations of [entity]. For a field, getter or setter this is
  /// always `null`.
  ParameterStructure get invokedParameters => null;

  /// Whether this member has any potential but unregistered dynamic reads,
  /// writes or invocations.
  bool get hasPendingDynamicUse =>
      hasPendingDynamicInvoke ||
      hasPendingDynamicRead ||
      hasPendingDynamicWrite;

  /// Whether this member has any potential but unregistered dynamic
  /// invocations.
  bool get hasPendingDynamicInvoke =>
      potentialInvokes.contains(Access.dynamicAccess);

  /// Whether this member has any potential but unregistered dynamic reads.
  bool get hasPendingDynamicRead =>
      potentialReads.contains(Access.dynamicAccess);

  /// Whether this member has any potential but unregistered dynamic writes.
  bool get hasPendingDynamicWrite =>
      potentialWrites.contains(Access.dynamicAccess);

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
  EnumSet<MemberUse> read(EnumSet<Access> accesses) => MemberUses.NONE;

  /// Registers a write of a value to [entity] and returns the new [MemberUse]s
  /// that it caused.
  EnumSet<MemberUse> write(EnumSet<Access> accesses) => MemberUses.NONE;

  /// Registers an invocation on the value of [entity] and returns the new
  /// [MemberUse]s that it caused.
  ///
  /// For a function this is a normal invocation, for a field this is a read
  /// access followed by an invocation of the function-like value.
  EnumSet<MemberUse> invoke(
          EnumSet<Access> accesses, CallStructure callStructure) =>
      MemberUses.NONE;

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
        hasPendingDynamicRead == other.hasPendingDynamicRead &&
        hasPendingDynamicWrite == other.hasPendingDynamicWrite &&
        hasPendingDynamicInvoke == other.hasPendingDynamicInvoke &&
        hasPendingDynamicUse == other.hasPendingDynamicUse &&
        _pendingUse == other._pendingUse &&
        _appliedUse == other._appliedUse &&
        reads == other.reads &&
        writes == other.writes &&
        invokes == other.invokes &&
        potentialReads == other.potentialReads &&
        potentialWrites == other.potentialWrites &&
        potentialInvokes == other.potentialInvokes &&
        invokedParameters == other.invokedParameters;
  }
}

/// Member usage tracking for a getter or setter.
class PropertyUsage extends MemberUsage {
  @override
  final EnumSet<Access> potentialReads;

  @override
  final EnumSet<Access> potentialWrites;

  @override
  final EnumSet<Access> potentialInvokes;

  @override
  final EnumSet<Access> reads;

  @override
  final EnumSet<Access> writes;

  @override
  final EnumSet<Access> invokes;

  PropertyUsage.cloned(MemberEntity member, EnumSet<MemberUse> pendingUse,
      {this.potentialReads,
      this.potentialWrites,
      this.potentialInvokes,
      this.reads,
      this.writes,
      this.invokes})
      : assert(potentialReads != null),
        assert(potentialWrites != null),
        assert(potentialInvokes != null),
        assert(reads != null),
        assert(writes != null),
        assert(invokes != null),
        super.cloned(member, pendingUse);

  PropertyUsage(MemberEntity member,
      {this.potentialReads, this.potentialWrites, this.potentialInvokes})
      : reads = new EnumSet(),
        writes = new EnumSet(),
        invokes = new EnumSet(),
        assert(potentialReads != null),
        assert(potentialWrites != null),
        assert(potentialInvokes != null),
        super.internal(member);

  @override
  EnumSet<MemberUse> read(EnumSet<Access> accesses) {
    bool alreadyHasRead = hasRead;
    reads.addAll(potentialReads.removeAll(accesses));
    if (alreadyHasRead) {
      return MemberUses.NONE;
    }
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> write(EnumSet<Access> accesses) {
    bool alreadyHasWrite = hasWrite;
    writes.addAll(potentialWrites.removeAll(accesses));
    if (alreadyHasWrite) {
      return MemberUses.NONE;
    }
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> invoke(
      EnumSet<Access> accesses, CallStructure callStructure) {
    // We use `hasRead` here instead of `hasInvoke` because getters only have
    // 'normal use' (they cannot be closurized). This means that invoking an
    // already read getter does not result a new member use.
    bool alreadyHasRead = hasRead;
    reads.addAll(potentialReads.removeAll(Accesses.staticAccess));
    invokes.addAll(potentialInvokes.removeAll(accesses));
    if (alreadyHasRead) {
      return MemberUses.NONE;
    }
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  MemberUsage clone() {
    return new PropertyUsage.cloned(entity, _pendingUse.clone(),
        potentialReads: potentialReads.clone(),
        potentialWrites: potentialWrites.clone(),
        potentialInvokes: potentialInvokes.clone(),
        reads: reads.clone(),
        writes: writes.clone(),
        invokes: invokes.clone());
  }

  @override
  String toString() => 'PropertyUsage($entity,'
      'reads=${reads.iterable(Access.values)},'
      'writes=${writes.iterable(Access.values)},'
      'invokes=${invokes.iterable(Access.values)},'
      'potentialReads=${potentialReads.iterable(Access.values)},'
      'potentialWrites=${potentialWrites.iterable(Access.values)},'
      'potentialInvokes=${potentialInvokes.iterable(Access.values)},'
      'pendingUse=${_pendingUse.iterable(MemberUse.values)},'
      'initialConstants=${initialConstants?.map((c) => c.toStructuredText(null))})';
}

/// Member usage tracking for a field.
class FieldUsage extends MemberUsage {
  @override
  bool hasInit;

  @override
  final EnumSet<Access> potentialReads;

  @override
  final EnumSet<Access> potentialWrites;

  @override
  final EnumSet<Access> potentialInvokes;

  @override
  final EnumSet<Access> reads;

  @override
  final EnumSet<Access> invokes;

  @override
  final EnumSet<Access> writes;

  List<ConstantValue> _initialConstants;

  FieldUsage.cloned(FieldEntity field, EnumSet<MemberUse> pendingUse,
      {this.potentialReads,
      this.potentialWrites,
      this.potentialInvokes,
      this.hasInit,
      this.reads,
      this.writes,
      this.invokes})
      : assert(potentialReads != null),
        assert(potentialWrites != null),
        assert(potentialInvokes != null),
        assert(reads != null),
        assert(writes != null),
        assert(invokes != null),
        super.cloned(field, pendingUse);

  FieldUsage(FieldEntity field,
      {this.potentialReads, this.potentialWrites, this.potentialInvokes})
      : hasInit = false,
        reads = new EnumSet(),
        writes = new EnumSet(),
        invokes = new EnumSet(),
        assert(potentialReads != null),
        assert(potentialWrites != null),
        assert(potentialInvokes != null),
        super.internal(field);

  @override
  Iterable<ConstantValue> get initialConstants => _initialConstants ?? const [];

  @override
  EnumSet<MemberUse> init() {
    if (hasInit) {
      return MemberUses.NONE;
    }
    hasInit = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> constantInit(ConstantValue constant) {
    _initialConstants ??= [];
    _initialConstants.add(constant);
    return init();
  }

  @override
  bool get hasRead => reads.isNotEmpty;

  @override
  EnumSet<MemberUse> read(EnumSet<Access> accesses) {
    bool alreadyHasRead = hasRead;
    reads.addAll(potentialReads.removeAll(accesses));
    if (alreadyHasRead) {
      return MemberUses.NONE;
    }
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  bool get hasWrite => writes.isNotEmpty;

  @override
  EnumSet<MemberUse> write(EnumSet<Access> accesses) {
    bool alreadyHasWrite = hasWrite;
    writes.addAll(potentialWrites.removeAll(accesses));
    if (alreadyHasWrite) {
      return MemberUses.NONE;
    }
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> invoke(
      EnumSet<Access> accesses, CallStructure callStructure) {
    // We use `hasRead` here instead of `hasInvoke` because fields only have
    // 'normal use' (they cannot be closurized). This means that invoking an
    // already read field does not result a new member use.
    bool alreadyHasRead = hasRead;
    reads.addAll(potentialReads.removeAll(Accesses.staticAccess));
    invokes.addAll(potentialInvokes.removeAll(accesses));
    if (alreadyHasRead) {
      return MemberUses.NONE;
    }
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  MemberUsage clone() {
    return new FieldUsage.cloned(entity, _pendingUse.clone(),
        potentialReads: potentialReads.clone(),
        potentialWrites: potentialWrites.clone(),
        potentialInvokes: potentialInvokes.clone(),
        hasInit: hasInit,
        reads: reads.clone(),
        writes: writes.clone(),
        invokes: invokes.clone());
  }

  @override
  String toString() => 'FieldUsage($entity,hasInit=$hasInit,'
      'reads=${reads.iterable(Access.values)},'
      'writes=${writes.iterable(Access.values)},'
      'invokes=${invokes.iterable(Access.values)},'
      'potentialReads=${potentialReads.iterable(Access.values)},'
      'potentialWrites=${potentialWrites.iterable(Access.values)},'
      'potentialInvokes=${potentialInvokes.iterable(Access.values)},'
      'pendingUse=${_pendingUse.iterable(MemberUse.values)},'
      'initialConstants=${initialConstants.map((c) => c.toStructuredText(null))})';
}

/// Member usage tracking for a constructor or method.
class MethodUsage extends MemberUsage {
  @override
  final EnumSet<Access> potentialReads;

  @override
  final EnumSet<Access> potentialInvokes;

  @override
  final EnumSet<Access> reads;

  @override
  final EnumSet<Access> invokes;

  final ParameterUsage parameterUsage;

  MethodUsage.cloned(FunctionEntity function, this.parameterUsage,
      EnumSet<MemberUse> pendingUse,
      {this.potentialReads, this.reads, this.potentialInvokes, this.invokes})
      : assert(potentialReads != null),
        assert(potentialInvokes != null),
        assert(reads != null),
        assert(invokes != null),
        super.cloned(function, pendingUse);

  MethodUsage(FunctionEntity function,
      {this.potentialReads, this.potentialInvokes})
      : reads = new EnumSet(),
        invokes = new EnumSet(),
        parameterUsage = new ParameterUsage(function.parameterStructure),
        assert(potentialReads != null),
        assert(potentialInvokes != null),
        super.internal(function);

  @override
  bool get hasInvoke => invokes.isNotEmpty && parameterUsage.hasInvoke;

  @override
  EnumSet<MemberUse> get _originalUse =>
      entity.isInstanceMember ? MemberUses.ALL_INSTANCE : MemberUses.ALL_STATIC;

  @override
  EnumSet<MemberUse> read(EnumSet<Access> accesses) {
    bool alreadyHasInvoke = hasInvoke;
    bool alreadyHasRead = hasRead;
    reads.addAll(potentialReads.removeAll(accesses));
    invokes.addAll(potentialInvokes.removeAll(Accesses.dynamicAccess));
    parameterUsage.fullyUse();
    if (alreadyHasInvoke) {
      if (alreadyHasRead) {
        return MemberUses.NONE;
      }
      return _pendingUse.removeAll(entity.isInstanceMember
          ? MemberUses.CLOSURIZE_INSTANCE_ONLY
          : MemberUses.CLOSURIZE_STATIC_ONLY);
    } else if (alreadyHasRead) {
      return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
    } else {
      return _pendingUse.removeAll(entity.isInstanceMember
          ? MemberUses.ALL_INSTANCE
          : MemberUses.ALL_STATIC);
    }
  }

  @override
  EnumSet<MemberUse> invoke(
      EnumSet<Access> accesses, CallStructure callStructure) {
    bool alreadyHasInvoke = hasInvoke;
    parameterUsage.invoke(callStructure);
    invokes.addAll(potentialInvokes.removeAll(accesses));
    if (alreadyHasInvoke) {
      return MemberUses.NONE;
    } else {
      return _pendingUse
          .removeAll(hasRead ? MemberUses.NONE : MemberUses.NORMAL_ONLY);
    }
  }

  @override
  ParameterStructure get invokedParameters => parameterUsage.invokedParameters;

  @override
  bool get hasPendingDynamicInvoke =>
      potentialInvokes.contains(Access.dynamicAccess) ||
      (invokes.contains(Access.dynamicAccess) && !parameterUsage.isFullyUsed);

  @override
  MemberUsage clone() {
    return new MethodUsage.cloned(
        entity, parameterUsage.clone(), _pendingUse.clone(),
        reads: reads.clone(),
        potentialReads: potentialReads.clone(),
        invokes: invokes.clone(),
        potentialInvokes: potentialInvokes.clone());
  }

  @override
  String toString() => 'MethodUsage($entity,'
      'reads=${reads.iterable(Access.values)},'
      'invokes=${invokes.iterable(Access.values)},'
      'parameterUsage=${parameterUsage},'
      'potentialReads=${potentialReads.iterable(Access.values)},'
      'potentialInvokes=${potentialInvokes.iterable(Access.values)},'
      'pendingUse=${_pendingUse.iterable(MemberUse.values)})';
}

/// Enum class for the possible kind of use of [MemberEntity] objects.
enum MemberUse {
  /// Read or write of a field, or invocation of a method.
  NORMAL,

  /// Tear-off of an instance method.
  CLOSURIZE_INSTANCE,

  /// Tear-off of a static method.
  CLOSURIZE_STATIC,
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
            _parameterStructure.requiredPositionalParameters
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
        _parameterStructure.requiredPositionalParameters,
        _providedPositionalParameters ??
            _parameterStructure.positionalParameters,
        _unprovidedNamedParameters == null
            ? _parameterStructure.namedParameters
            : _parameterStructure.namedParameters
                .where((n) => !_unprovidedNamedParameters.contains(n))
                .toList(),
        _parameterStructure.requiredNamedParameters,
        _areAllTypeParametersProvided ? _parameterStructure.typeParameters : 0);
  }

  ParameterUsage clone() {
    return new ParameterUsage.cloned(_parameterStructure,
        hasInvoke: _hasInvoke,
        providedPositionalParameters: _providedPositionalParameters,
        areAllTypeParametersProvided: _areAllTypeParametersProvided,
        unprovidedNamedParameters: _unprovidedNamedParameters?.toSet());
  }

  @override
  String toString() {
    return 'ParameterUsage('
        '_hasInvoke=$_hasInvoke,'
        '_providedPositionalParameters=$_providedPositionalParameters,'
        '_areAllTypeParametersProvided=$_areAllTypeParametersProvided,'
        '_unprovidedNamedParameters=$_unprovidedNamedParameters)';
  }
}

/// Enum for member access kinds use in [MemberUsage] computation during
/// resolution or codegen enqueueing.
enum Access {
  /// Statically bound access of a member.
  staticAccess,

  /// Dynamically bound access of a member.
  dynamicAccess,

  /// Direct access of a super class member.
  superAccess,
}

/// Access sets used for registration of member usage.
class Accesses {
  /// Statically bound access of a member.
  static const EnumSet<Access> staticAccess = const EnumSet<Access>.fixed(1);

  /// Dynamically bound access of a member. This implies the statically bound
  /// access of the member.
  static const EnumSet<Access> dynamicAccess = const EnumSet<Access>.fixed(3);

  /// Direct access of a super class member. This implies the statically bound
  /// access of the member.
  static const EnumSet<Access> superAccess = const EnumSet<Access>.fixed(5);
}

/// The accesses of a member collected during closed world computation.
class MemberAccess {
  static const String tag = 'MemberAccess';

  final EnumSet<Access> reads;
  final EnumSet<Access> writes;
  final EnumSet<Access> invokes;

  MemberAccess(this.reads, this.writes, this.invokes);

  factory MemberAccess.readFromDataSource(DataSource source) {
    source.begin(tag);
    EnumSet<Access> reads = new EnumSet.fixed(source.readInt());
    EnumSet<Access> writes = new EnumSet.fixed(source.readInt());
    EnumSet<Access> invokes = new EnumSet.fixed(source.readInt());
    source.end(tag);
    return new MemberAccess(reads, writes, invokes);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeInt(reads.value);
    sink.writeInt(writes.value);
    sink.writeInt(invokes.value);
    sink.end(tag);
  }
}
