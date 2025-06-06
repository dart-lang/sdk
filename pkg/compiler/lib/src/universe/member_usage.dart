// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import '../common.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../js_model/closure.dart' show JContextField;
import '../serialization/serialization.dart';
import '../util/enumset.dart';
import 'call_structure.dart';

abstract class AbstractUsage<E extends Enum> {
  EnumSet<E> _pendingUse = EnumSet.empty();

  AbstractUsage.cloned(this._pendingUse);

  AbstractUsage() {
    _pendingUse = _originalUse;
  }

  /// Returns the uses of [entity] that have been registered.
  EnumSet<E> get _appliedUse => _originalUse.setMinus(_pendingUse);

  EnumSet<E> get _originalUse;

  /// `true` if the [_appliedUse] is non-empty.
  bool get hasUse => _appliedUse.isNotEmpty;

  /// Returns `true` if [other] has the same original and pending usage as this.
  bool hasSameUsage(AbstractUsage<E> other) {
    if (identical(this, other)) return true;
    return _originalUse == other._originalUse &&
        _pendingUse == other._pendingUse;
  }
}

/// Registry for the observed use of a member [entity] in the open world.
abstract class MemberUsage extends AbstractUsage<MemberUse> {
  final MemberEntity entity;

  MemberUsage.internal(this.entity) : super();

  MemberUsage.cloned(this.entity, EnumSet<MemberUse> pendingUse)
    : super.cloned(pendingUse);

  factory MemberUsage(MemberEntity member, {MemberAccess? potentialAccess}) {
    /// Create the set of potential accesses to [member], limited to [original]
    /// if provided.
    EnumSet<Access> createPotentialAccessSet(EnumSet<Access>? original) {
      if (original != null) {
        return original;
      }
      if (member.isTopLevel || member.isStatic || member is ConstructorEntity) {
        // TODO(johnniwinther): Track super constructor invocations?
        return EnumSet.fromValues([Access.staticAccess]);
      } else if (member.isInstanceMember) {
        return EnumSet.allValues(Access.values);
      } else {
        assert(member is JContextField, "Unexpected member: $member");
        return EnumSet.empty();
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

    if (member is FieldEntity) {
      if (member.isAssignable) {
        return FieldUsage(
          member,
          potentialReads: createPotentialReads(),
          potentialWrites: createPotentialWrites(),
          potentialInvokes: createPotentialInvokes(),
        );
      } else {
        return FieldUsage(
          member,
          potentialReads: createPotentialReads(),
          potentialWrites: EnumSet.empty(),
          potentialInvokes: createPotentialInvokes(),
        );
      }
    } else if (member is FunctionEntity) {
      if (member.isGetter) {
        return PropertyUsage(
          member,
          potentialReads: createPotentialReads(),
          potentialWrites: EnumSet.empty(),
          potentialInvokes: createPotentialInvokes(),
        );
      } else if (member.isSetter) {
        return PropertyUsage(
          member,
          potentialReads: EnumSet.empty(),
          potentialWrites: createPotentialWrites(),
          potentialInvokes: EnumSet.empty(),
        );
      } else if (member is ConstructorEntity) {
        return MethodUsage(
          member,
          potentialReads: EnumSet.empty(),
          potentialInvokes: createPotentialInvokes(),
        );
      } else {
        return MethodUsage(
          member,
          potentialReads: createPotentialReads(),
          potentialInvokes: createPotentialInvokes(),
        );
      }
    }
    throw failedAt(member, "Unexpected member: $member");
  }

  /// `true` if [entity] has been initialized.
  bool get hasInit => true;

  /// The set of constant initial values for a field.
  Iterable<ConstantValue>? get initialConstants => null;

  /// `true` if [entity] has been read as a value. For a field this is a normal
  /// read access, for a function this is a closurization.
  bool get hasRead => reads.isNotEmpty;

  /// The set of potential read accesses to this member that have not yet
  /// been registered.
  EnumSet<Access> get potentialReads => const EnumSet.empty();

  /// The set of registered read accesses to this member.
  EnumSet<Access> get reads => const EnumSet.empty();

  /// `true` if a value has been written to [entity].
  bool get hasWrite => writes.isNotEmpty;

  /// The set of potential write accesses to this member that have not yet
  /// been registered.
  EnumSet<Access> get potentialWrites => const EnumSet.empty();

  /// The set of registered write accesses to this member.
  EnumSet<Access> get writes => const EnumSet.empty();

  /// `true` if an invocation has been performed on the value [entity]. For a
  /// function this is a normal invocation, for a field this is a read access
  /// followed by an invocation of the function-like value.
  bool get hasInvoke => invokes.isNotEmpty;

  /// The set of potential invocation accesses to this member that have not yet
  /// been registered.
  EnumSet<Access> get potentialInvokes => const EnumSet.empty();

  /// The set of registered invocation accesses to this member.
  EnumSet<Access> get invokes => const EnumSet.empty();

  /// Returns the [ParameterStructure] corresponding to the parameters that are
  /// used in invocations of [entity]. For a field, getter or setter this is
  /// always `null`.
  ParameterStructure? get invokedParameters => null;

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
  EnumSet<MemberUse> init() => MemberUses.none;

  /// Registers the [entity] has been initialized with [constant] and returns
  /// the new [MemberUse]s that it caused.
  ///
  /// For a field this is the initial write access, for a function this is a
  /// no-op.
  EnumSet<MemberUse> constantInit(ConstantValue constant) => MemberUses.none;

  /// Registers a read of the value of [entity] and returns the new [MemberUse]s
  /// that it caused.
  ///
  /// For a field this is a normal read access, for a function this is a
  /// closurization.
  EnumSet<MemberUse> read(EnumSet<Access> accesses) => MemberUses.none;

  /// Registers a write of a value to [entity] and returns the new [MemberUse]s
  /// that it caused.
  EnumSet<MemberUse> write(EnumSet<Access> accesses) => MemberUses.none;

  /// Registers an invocation on the value of [entity] and returns the new
  /// [MemberUse]s that it caused.
  ///
  /// For a function this is a normal invocation, for a field this is a read
  /// access followed by an invocation of the function-like value.
  ///
  /// If [forceAccesses] is true, the provided [accesses] will be applied to
  /// this usage even if there are no matching pending invokes.
  EnumSet<MemberUse> invoke(
    EnumSet<Access> accesses,
    CallStructure callStructure, {
    bool forceAccesses = false,
  }) => MemberUses.none;

  @override
  EnumSet<MemberUse> get _originalUse => MemberUses.normalOnly;

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
  EnumSet<Access> potentialReads;

  @override
  EnumSet<Access> potentialWrites;

  @override
  EnumSet<Access> potentialInvokes;

  @override
  EnumSet<Access> reads;

  @override
  EnumSet<Access> writes;

  @override
  EnumSet<Access> invokes;

  PropertyUsage.cloned(
    super.member,
    super.pendingUse, {
    required this.potentialReads,
    required this.potentialWrites,
    required this.potentialInvokes,
    required this.reads,
    required this.writes,
    required this.invokes,
  }) : super.cloned();

  PropertyUsage(
    super.member, {
    required this.potentialReads,
    required this.potentialWrites,
    required this.potentialInvokes,
  }) : reads = EnumSet.empty(),
       writes = EnumSet.empty(),
       invokes = EnumSet.empty(),
       super.internal();

  @override
  EnumSet<MemberUse> read(EnumSet<Access> accesses) {
    bool alreadyHasRead = hasRead;
    reads = reads.union(potentialReads.intersection(accesses));
    potentialReads = potentialReads.setMinus(accesses);
    if (alreadyHasRead) {
      return MemberUses.none;
    }
    final removed = _pendingUse.intersection(MemberUses.normalOnly);
    _pendingUse = _pendingUse.setMinus(MemberUses.normalOnly);
    return removed;
  }

  @override
  EnumSet<MemberUse> write(EnumSet<Access> accesses) {
    bool alreadyHasWrite = hasWrite;
    writes = writes.union(potentialWrites.intersection(accesses));
    potentialWrites = potentialWrites.setMinus(accesses);
    if (alreadyHasWrite) {
      return MemberUses.none;
    }
    final removed = _pendingUse.intersection(MemberUses.normalOnly);
    _pendingUse = _pendingUse.setMinus(MemberUses.normalOnly);
    return removed;
  }

  @override
  EnumSet<MemberUse> invoke(
    EnumSet<Access> accesses,
    CallStructure callStructure, {
    bool forceAccesses = false,
  }) {
    // We use `hasRead` here instead of `hasInvoke` because getters only have
    // 'normal use' (they cannot be closurized). This means that invoking an
    // already read getter does not result a new member use.
    bool alreadyHasRead = hasRead;
    reads = reads.union(potentialReads.intersection(Accesses.staticAccess));
    potentialReads = potentialReads.setMinus(Accesses.staticAccess);
    final removedPotentialInvokes = potentialInvokes.intersection(accesses);
    potentialInvokes = potentialInvokes.setMinus(accesses);
    if (forceAccesses) {
      invokes = invokes.union(accesses);
    } else {
      invokes = invokes.union(removedPotentialInvokes);
    }
    if (alreadyHasRead) {
      return MemberUses.none;
    }

    final removed = _pendingUse.intersection(MemberUses.normalOnly);
    _pendingUse = _pendingUse.setMinus(MemberUses.normalOnly);
    return removed;
  }

  @override
  MemberUsage clone() {
    return PropertyUsage.cloned(
      entity,
      _pendingUse,
      potentialReads: potentialReads,
      potentialWrites: potentialWrites,
      potentialInvokes: potentialInvokes,
      reads: reads,
      writes: writes,
      invokes: invokes,
    );
  }

  @override
  String toString() =>
      'PropertyUsage($entity,'
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
  EnumSet<Access> potentialReads;

  @override
  EnumSet<Access> potentialWrites;

  @override
  EnumSet<Access> potentialInvokes;

  @override
  EnumSet<Access> reads;

  @override
  EnumSet<Access> invokes;

  @override
  EnumSet<Access> writes;

  List<ConstantValue>? _initialConstants;

  FieldUsage.cloned(
    FieldEntity super.field,
    super.pendingUse, {
    required this.potentialReads,
    required this.potentialWrites,
    required this.potentialInvokes,
    required this.hasInit,
    required this.reads,
    required this.writes,
    required this.invokes,
  }) : super.cloned();

  FieldUsage(
    FieldEntity super.field, {
    required this.potentialReads,
    required this.potentialWrites,
    required this.potentialInvokes,
  }) : hasInit = false,
       reads = EnumSet.empty(),
       writes = EnumSet.empty(),
       invokes = EnumSet.empty(),
       super.internal();

  @override
  Iterable<ConstantValue> get initialConstants => _initialConstants ?? const [];

  @override
  EnumSet<MemberUse> init() {
    if (hasInit) {
      return MemberUses.none;
    }
    hasInit = true;
    final removed = _pendingUse.intersection(MemberUses.normalOnly);
    _pendingUse = _pendingUse.setMinus(MemberUses.normalOnly);
    return removed;
  }

  @override
  EnumSet<MemberUse> constantInit(ConstantValue constant) {
    (_initialConstants ??= []).add(constant);
    return init();
  }

  @override
  bool get hasRead => reads.isNotEmpty;

  @override
  EnumSet<MemberUse> read(EnumSet<Access> accesses) {
    bool alreadyHasRead = hasRead;
    reads = reads.union(potentialReads.intersection(accesses));
    potentialReads = potentialReads.setMinus(accesses);
    if (alreadyHasRead) {
      return MemberUses.none;
    }
    final removed = _pendingUse.intersection(MemberUses.normalOnly);
    _pendingUse = _pendingUse.setMinus(MemberUses.normalOnly);
    return removed;
  }

  @override
  bool get hasWrite => writes.isNotEmpty;

  @override
  EnumSet<MemberUse> write(EnumSet<Access> accesses) {
    bool alreadyHasWrite = hasWrite;
    writes = writes.union(potentialWrites.intersection(accesses));
    potentialWrites = potentialWrites.setMinus(accesses);
    if (alreadyHasWrite) {
      return MemberUses.none;
    }
    final removed = _pendingUse.intersection(MemberUses.normalOnly);
    _pendingUse = _pendingUse.setMinus(MemberUses.normalOnly);
    return removed;
  }

  @override
  EnumSet<MemberUse> invoke(
    EnumSet<Access> accesses,
    CallStructure callStructure, {
    bool forceAccesses = false,
  }) {
    // We use `hasRead` here instead of `hasInvoke` because fields only have
    // 'normal use' (they cannot be closurized). This means that invoking an
    // already read field does not result a new member use.
    bool alreadyHasRead = hasRead;
    reads = reads.union(potentialReads.intersection(Accesses.staticAccess));
    potentialReads = potentialReads.setMinus(Accesses.staticAccess);
    final removedPotentialInvokes = potentialInvokes.intersection(accesses);
    potentialInvokes = potentialInvokes.setMinus(accesses);
    if (forceAccesses) {
      invokes = invokes.union(accesses);
    } else {
      invokes = invokes.union(removedPotentialInvokes);
    }
    if (alreadyHasRead) {
      return MemberUses.none;
    }
    final removed = _pendingUse.intersection(MemberUses.normalOnly);
    _pendingUse = _pendingUse.setMinus(MemberUses.normalOnly);
    return removed;
  }

  @override
  MemberUsage clone() {
    return FieldUsage.cloned(
      entity as FieldEntity,
      _pendingUse,
      potentialReads: potentialReads,
      potentialWrites: potentialWrites,
      potentialInvokes: potentialInvokes,
      hasInit: hasInit,
      reads: reads,
      writes: writes,
      invokes: invokes,
    );
  }

  @override
  String toString() =>
      'FieldUsage($entity,hasInit=$hasInit,'
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
  EnumSet<Access> potentialReads;

  @override
  EnumSet<Access> potentialInvokes;

  @override
  EnumSet<Access> reads;

  @override
  EnumSet<Access> invokes;

  final ParameterUsage parameterUsage;

  MethodUsage.cloned(
    super.function,
    this.parameterUsage,
    super.pendingUse, {
    required this.potentialReads,
    required this.reads,
    required this.potentialInvokes,
    required this.invokes,
  }) : super.cloned();

  MethodUsage(
    FunctionEntity super.function, {
    required this.potentialReads,
    required this.potentialInvokes,
  }) : reads = EnumSet.empty(),
       invokes = EnumSet.empty(),
       parameterUsage = ParameterUsage(function.parameterStructure),
       super.internal();

  @override
  bool get hasInvoke => invokes.isNotEmpty && parameterUsage.hasInvoke;

  @override
  EnumSet<MemberUse> get _originalUse =>
      entity.isInstanceMember ? MemberUses.allInstance : MemberUses.allStatic;

  @override
  EnumSet<MemberUse> read(EnumSet<Access> accesses) {
    bool alreadyHasInvoke = hasInvoke;
    bool alreadyHasRead = hasRead;
    reads = reads.union(potentialReads.intersection(accesses));
    potentialReads = potentialReads.setMinus(accesses);
    invokes = invokes.union(
      potentialInvokes.intersection(Accesses.dynamicAccess),
    );
    potentialInvokes = potentialInvokes.setMinus(Accesses.dynamicAccess);
    parameterUsage.fullyUse();
    if (alreadyHasInvoke) {
      if (alreadyHasRead) {
        return MemberUses.none;
      }
      final memberUses = entity.isInstanceMember
          ? MemberUses.closurizeInstanceOnly
          : MemberUses.closurizeStaticOnly;
      final removed = _pendingUse.intersection(memberUses);
      _pendingUse = _pendingUse.setMinus(memberUses);
      return removed;
    } else if (alreadyHasRead) {
      final removed = _pendingUse.intersection(MemberUses.normalOnly);
      _pendingUse = _pendingUse.setMinus(MemberUses.normalOnly);
      return removed;
    } else {
      final memberUses = entity.isInstanceMember
          ? MemberUses.allInstance
          : MemberUses.allStatic;
      final removed = _pendingUse.intersection(memberUses);
      _pendingUse = _pendingUse.setMinus(memberUses);
      return removed;
    }
  }

  @override
  EnumSet<MemberUse> invoke(
    EnumSet<Access> accesses,
    CallStructure callStructure, {
    bool forceAccesses = false,
  }) {
    bool alreadyHasInvoke = hasInvoke;
    parameterUsage.invoke(callStructure);
    final removedPotentialInvokes = potentialInvokes.intersection(accesses);
    potentialInvokes = potentialInvokes.setMinus(accesses);
    if (forceAccesses) {
      invokes = invokes.union(accesses);
    } else {
      invokes = invokes.union(removedPotentialInvokes);
    }
    if (alreadyHasInvoke) {
      return MemberUses.none;
    } else {
      final memberUses = hasRead ? MemberUses.none : MemberUses.normalOnly;
      final removed = _pendingUse.intersection(memberUses);
      _pendingUse = _pendingUse.setMinus(memberUses);
      return removed;
    }
  }

  @override
  ParameterStructure? get invokedParameters => parameterUsage.invokedParameters;

  @override
  bool get hasPendingDynamicInvoke =>
      potentialInvokes.contains(Access.dynamicAccess) ||
      (invokes.contains(Access.dynamicAccess) && !parameterUsage.isFullyUsed);

  @override
  MemberUsage clone() {
    return MethodUsage.cloned(
      entity as FunctionEntity,
      parameterUsage.clone(),
      _pendingUse,
      reads: reads,
      potentialReads: potentialReads,
      invokes: invokes,
      potentialInvokes: potentialInvokes,
    );
  }

  @override
  String toString() =>
      'MethodUsage($entity,'
      'reads=${reads.iterable(Access.values)},'
      'invokes=${invokes.iterable(Access.values)},'
      'parameterUsage=$parameterUsage,'
      'potentialReads=${potentialReads.iterable(Access.values)},'
      'potentialInvokes=${potentialInvokes.iterable(Access.values)},'
      'pendingUse=${_pendingUse.iterable(MemberUse.values)})';
}

/// Enum class for the possible kind of use of [MemberEntity] objects.
enum MemberUse {
  /// Read or write of a field, or invocation of a method.
  normal,

  /// Tear-off of an instance method.
  closurizeInstance,

  /// Tear-off of a static method.
  closurizeStatic,
}

/// Common [EnumSet]s used for [MemberUse].
class MemberUses {
  static const EnumSet<MemberUse> none = EnumSet.fromRawBits(0);
  static const EnumSet<MemberUse> normalOnly = EnumSet.fromRawBits(1);
  static const EnumSet<MemberUse> closurizeInstanceOnly = EnumSet.fromRawBits(
    2,
  );
  static const EnumSet<MemberUse> closurizeStaticOnly = EnumSet.fromRawBits(4);
  static const EnumSet<MemberUse> allInstance = EnumSet.fromRawBits(3);
  static const EnumSet<MemberUse> allStatic = EnumSet.fromRawBits(5);
}

typedef MemberUsedCallback =
    void Function(MemberEntity member, EnumSet<MemberUse> useSet);

/// Registry for the observed use of a class [entity] in the open world.
// TODO(johnniwinther): Merge this with [InstantiationInfo].
class ClassUsage extends AbstractUsage<ClassUse> {
  bool isInstantiated = false;
  bool isImplemented = false;

  final ClassEntity cls;

  ClassUsage(this.cls) : super();

  EnumSet<ClassUse> instantiate() {
    if (isInstantiated) {
      return ClassUses.none;
    }
    isInstantiated = true;
    final removed = _pendingUse.intersection(ClassUses.instantiatedOnly);
    _pendingUse = _pendingUse.setMinus(ClassUses.instantiatedOnly);
    return removed;
  }

  EnumSet<ClassUse> implement() {
    if (isImplemented) {
      return ClassUses.none;
    }
    isImplemented = true;
    final removed = _pendingUse.intersection(ClassUses.implementedOnly);
    _pendingUse = _pendingUse.setMinus(ClassUses.implementedOnly);
    return removed;
  }

  @override
  EnumSet<ClassUse> get _originalUse => ClassUses.all;

  @override
  String toString() => '$cls:${_appliedUse.iterable(ClassUse.values)}';
}

/// Enum class for the possible kind of use of [ClassEntity] objects.
enum ClassUse { instantiated, implemented }

/// Common [EnumSet]s used for [ClassUse].
class ClassUses {
  static const EnumSet<ClassUse> none = EnumSet.fromRawBits(0);
  static const EnumSet<ClassUse> instantiatedOnly = EnumSet.fromRawBits(1);
  static const EnumSet<ClassUse> implementedOnly = EnumSet.fromRawBits(2);
  static const EnumSet<ClassUse> all = EnumSet.fromRawBits(3);
}

typedef ClassUsedCallback =
    void Function(ClassEntity cls, EnumSet<ClassUse> useSet);

/// Object used for tracking parameter use in constructor and method
/// invocations.
class ParameterUsage {
  /// The original parameter structure of the method or constructor.
  final ParameterStructure _parameterStructure;

  /// `true` if the method or constructor has at least one invocation.
  bool _hasInvoke = false;

  /// The maximum number of (optional) positional parameters provided in
  /// invocations of the method or constructor.
  ///
  /// If all positional parameters having been provided this is set to `null`.
  int? _providedPositionalParameters;

  /// `true` if all type parameters have been provided in at least one
  /// invocation of the method or constructor.
  late bool _areAllTypeParametersProvided;

  /// The set of named parameters that have not yet been provided in any
  /// invocation of the method or constructor.
  ///
  /// If all named parameters have been provided this is set to `null`.
  Set<String>? _unprovidedNamedParameters;

  ParameterUsage(this._parameterStructure) {
    _areAllTypeParametersProvided = _parameterStructure.typeParameters == 0;
    _providedPositionalParameters =
        _parameterStructure.positionalParameters ==
            _parameterStructure.requiredPositionalParameters
        ? null
        : 0;
    if (_parameterStructure.namedParameters.isNotEmpty) {
      _unprovidedNamedParameters = Set<String>.from(
        _parameterStructure.namedParameters,
      );
    }
  }

  ParameterUsage.cloned(
    this._parameterStructure, {
    required bool hasInvoke,
    required int? providedPositionalParameters,
    required bool areAllTypeParametersProvided,
    required Set<String>? unprovidedNamedParameters,
  }) : _hasInvoke = hasInvoke,
       _providedPositionalParameters = providedPositionalParameters,
       _areAllTypeParametersProvided = areAllTypeParametersProvided,
       _unprovidedNamedParameters = unprovidedNamedParameters;

  bool invoke(CallStructure callStructure) {
    if (isFullyUsed) return false;
    _hasInvoke = true;
    bool changed = false;
    if (_providedPositionalParameters != null) {
      int newProvidedPositionalParameters = math.max(
        _providedPositionalParameters!,
        callStructure.positionalArgumentCount,
      );
      changed |=
          newProvidedPositionalParameters != _providedPositionalParameters;
      _providedPositionalParameters = newProvidedPositionalParameters;
      if (_providedPositionalParameters! >=
          _parameterStructure.positionalParameters) {
        _providedPositionalParameters = null;
      }
    }
    if (_unprovidedNamedParameters != null &&
        callStructure.namedArguments.isNotEmpty) {
      int providedNamedParametersCount = _unprovidedNamedParameters!.length;
      _unprovidedNamedParameters!.removeAll(callStructure.namedArguments);
      changed |=
          providedNamedParametersCount != _unprovidedNamedParameters!.length;
      if (_unprovidedNamedParameters!.isEmpty) {
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

  ParameterStructure? get invokedParameters {
    if (!_hasInvoke) return null;
    if (isFullyUsed) return _parameterStructure;
    return ParameterStructure(
      _parameterStructure.requiredPositionalParameters,
      _providedPositionalParameters ?? _parameterStructure.positionalParameters,
      _unprovidedNamedParameters == null
          ? _parameterStructure.namedParameters
          : _parameterStructure.namedParameters
                .where((n) => !_unprovidedNamedParameters!.contains(n))
                .toList(),
      _parameterStructure.requiredNamedParameters,
      _areAllTypeParametersProvided ? _parameterStructure.typeParameters : 0,
    );
  }

  ParameterUsage clone() {
    return ParameterUsage.cloned(
      _parameterStructure,
      hasInvoke: _hasInvoke,
      providedPositionalParameters: _providedPositionalParameters,
      areAllTypeParametersProvided: _areAllTypeParametersProvided,
      unprovidedNamedParameters: _unprovidedNamedParameters?.toSet(),
    );
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
  static const EnumSet<Access> staticAccess = EnumSet.fromRawBits(1);

  /// Dynamically bound access of a member. This implies the statically bound
  /// access of the member.
  static const EnumSet<Access> dynamicAccess = EnumSet.fromRawBits(3);

  /// Direct access of a super class member. This implies the statically bound
  /// access of the member.
  static const EnumSet<Access> superAccess = EnumSet.fromRawBits(5);
}

/// The accesses of a member collected during closed world computation.
class MemberAccess {
  static const String tag = 'MemberAccess';

  final EnumSet<Access> reads;
  final EnumSet<Access> writes;
  final EnumSet<Access> invokes;

  MemberAccess(this.reads, this.writes, this.invokes);

  factory MemberAccess.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    EnumSet<Access> reads = EnumSet.fromRawBits(source.readInt());
    EnumSet<Access> writes = EnumSet.fromRawBits(source.readInt());
    EnumSet<Access> invokes = EnumSet.fromRawBits(source.readInt());
    source.end(tag);
    return MemberAccess(reads, writes, invokes);
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeInt(reads.mask.bits);
    sink.writeInt(writes.mask.bits);
    sink.writeInt(invokes.mask.bits);
    sink.end(tag);
  }
}
