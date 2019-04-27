// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library world_builder;

import '../common_elements.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../ir/static_type.dart';
import '../js_backend/native_data.dart' show NativeBasicData;
import '../world.dart' show World, JClosedWorld, OpenWorld;
import 'selector.dart' show Selector;
import 'use.dart' show DynamicUse, StaticUse;

/// The combined constraints on receivers all the dynamic call sites of the same
/// selector.
///
/// For instance for these calls
///
///     class A {
///        foo(a, b) {}
///     }
///     class B {
///        foo(a, b) {}
///     }
///     class C {
///        foo(a, b) {}
///     }
///     new A().foo(a, b);
///     new B().foo(0, 42);
///
/// the selector constraints for dynamic calls to 'foo' with two positional
/// arguments could be 'receiver of exact instance `A` or `B`'.
abstract class SelectorConstraints {
  /// Returns `true` if [name] applies to [element] under these constraints
  /// given the closed [world].
  ///
  /// Consider for instance in this world:
  ///
  ///     class A {
  ///        foo(a, b) {}
  ///     }
  ///     class B {
  ///        foo(a, b) {}
  ///     }
  ///     new A().foo(a, b);
  ///
  /// Ideally the selector constraints for calls `foo` with two positional
  /// arguments apply to `A.foo` but `B.foo`.
  bool canHit(MemberEntity element, Name name, covariant World world);

  /// Returns `true` if at least one of the receivers matching these constraints
  /// in the closed [world] have no implementation matching [selector].
  ///
  /// For instance for this code snippet
  ///
  ///     class A {}
  ///     class B { foo() {} }
  ///     m(b) => (b ? new A() : new B()).foo();
  ///
  /// the potential receiver `new A()` has no implementation of `foo` and thus
  /// needs to handle the call through its `noSuchMethod` handler.
  bool needsNoSuchMethodHandling(Selector selector, covariant World world);
}

/// A mutable [SelectorConstraints] used in [WorldBuilder].
abstract class UniverseSelectorConstraints extends SelectorConstraints {
  /// Adds [constraint] to these selector constraints. Return `true` if the set
  /// of potential receivers expanded due to the new constraint.
  bool addReceiverConstraint(covariant Object constraint);
}

/// Strategy for computing the constraints on potential receivers of dynamic
/// call sites.
abstract class SelectorConstraintsStrategy {
  /// Create a [UniverseSelectorConstraints] to represent the global receiver
  /// constraints for dynamic call sites with [selector].
  UniverseSelectorConstraints createSelectorConstraints(
      Selector selector, Object initialConstraint);

  /// Returns `true`  if [member] is a potential target of [dynamicUse].
  bool appliedUnnamed(DynamicUse dynamicUse, MemberEntity member, World world);
}

/// Open world strategy that constrains instance member access to subtypes of
/// the static type of the receiver.
///
/// This strategy is used for Dart 2.
class StrongModeWorldStrategy implements SelectorConstraintsStrategy {
  const StrongModeWorldStrategy();

  @override
  StrongModeWorldConstraints createSelectorConstraints(
      Selector selector, Object initialConstraint) {
    return new StrongModeWorldConstraints()
      ..addReceiverConstraint(initialConstraint);
  }

  @override
  bool appliedUnnamed(
      DynamicUse dynamicUse, MemberEntity member, covariant OpenWorld world) {
    Selector selector = dynamicUse.selector;
    StrongModeConstraint constraint = dynamicUse.receiverConstraint;
    return selector.appliesUnnamed(member) &&
        (constraint == null ||
            constraint.canHit(member, selector.memberName, world));
  }
}

class StrongModeWorldConstraints extends UniverseSelectorConstraints {
  bool isAll = false;
  Set<StrongModeConstraint> _constraints;

  @override
  bool canHit(MemberEntity element, Name name, World world) {
    if (isAll) return true;
    if (_constraints == null) return false;
    for (StrongModeConstraint constraint in _constraints) {
      if (constraint.canHit(element, name, world)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool needsNoSuchMethodHandling(Selector selector, World world) {
    if (isAll) {
      return true;
    }
    if (_constraints != null) {
      for (StrongModeConstraint constraint in _constraints) {
        if (constraint.needsNoSuchMethodHandling(selector, world)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  bool addReceiverConstraint(StrongModeConstraint constraint) {
    if (isAll) return false;
    if (constraint?.cls == null) {
      isAll = true;
      _constraints = null;
      return true;
    }
    _constraints ??= new Set<StrongModeConstraint>();
    return _constraints.add(constraint);
  }

  @override
  String toString() {
    if (isAll) {
      return '<all>';
    } else if (_constraints != null) {
      return '<${_constraints.map((c) => c.cls).join(',')}>';
    } else {
      return '<none>';
    }
  }
}

class StrongModeConstraint {
  final ClassEntity cls;
  final ClassRelation relation;

  factory StrongModeConstraint(CommonElements commonElements,
      NativeBasicData nativeBasicData, ClassEntity cls,
      [ClassRelation relation = ClassRelation.subtype]) {
    if (nativeBasicData.isJsInteropClass(cls)) {
      // We can not tell js-interop classes apart, so we just assume the
      // receiver could be any js-interop class.
      cls = commonElements.jsJavaScriptObjectClass;
      relation = ClassRelation.subtype;
    }
    return new StrongModeConstraint.internal(cls, relation);
  }

  const StrongModeConstraint.internal(this.cls, this.relation);

  bool needsNoSuchMethodHandling(Selector selector, World world) => true;

  bool canHit(MemberEntity element, Name name, OpenWorld world) {
    return world.isInheritedIn(element, cls, relation);
  }

  bool get isExact => relation == ClassRelation.exact;

  bool get isThis => relation == ClassRelation.thisExpression;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StrongModeConstraint &&
        cls == other.cls &&
        relation == other.relation;
  }

  @override
  int get hashCode => cls.hashCode * 13;

  @override
  String toString() => 'StrongModeConstraint($cls,$relation)';
}

/// The [WorldBuilder] is an auxiliary class used in the process of computing
/// the [JClosedWorld].
// TODO(johnniwinther): Move common implementation to a [WorldBuilderBase] when
// universes and worlds have been unified.
abstract class WorldBuilder {
  /// All directly instantiated classes, that is, classes with a generative
  /// constructor that has been called directly and not only through a
  /// super-call.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<ClassEntity> get directlyInstantiatedClasses;
}

abstract class WorldBuilderBase {
  final Map<Entity, Set<DartType>> staticTypeArgumentDependencies =
      <Entity, Set<DartType>>{};

  final Map<Selector, Set<DartType>> dynamicTypeArgumentDependencies =
      <Selector, Set<DartType>>{};

  final Set<TypeVariableType> typeVariableTypeLiterals =
      new Set<TypeVariableType>();

  void _registerStaticTypeArgumentDependency(
      Entity element, List<DartType> typeArguments) {
    staticTypeArgumentDependencies.putIfAbsent(
        element, () => new Set<DartType>())
      ..addAll(typeArguments);
  }

  void _registerDynamicTypeArgumentDependency(
      Selector selector, List<DartType> typeArguments) {
    dynamicTypeArgumentDependencies.putIfAbsent(
        selector, () => new Set<DartType>())
      ..addAll(typeArguments);
  }

  void registerStaticInvocation(StaticUse staticUse) {
    if (staticUse.typeArguments == null || staticUse.typeArguments.isEmpty) {
      return;
    }
    _registerStaticTypeArgumentDependency(
        staticUse.element, staticUse.typeArguments);
  }

  void registerDynamicInvocation(
      Selector selector, List<DartType> typeArguments) {
    if (typeArguments.isEmpty) return;
    _registerDynamicTypeArgumentDependency(selector, typeArguments);
  }

  void registerTypeVariableTypeLiteral(TypeVariableType typeVariable) {
    typeVariableTypeLiterals.add(typeVariable);
  }
}
