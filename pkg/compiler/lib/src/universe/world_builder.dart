// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library world_builder;

import '../common/elements.dart';
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../ir/static_type.dart';
import '../js_backend/native_data.dart' show NativeBasicData;
import '../world.dart' show World;
import 'selector.dart' show Selector;
import 'use.dart' show DynamicUse, StaticUse;
import 'resolution_world_builder.dart' show ResolutionWorldBuilder;

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
///     A().foo(a, b);
///     B().foo(0, 42);
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
  ///     A().foo(a, b);
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
  ///     m(b) => (b ? A() : B()).foo();
  ///
  /// the potential receiver `new A()` has no implementation of `foo` and thus
  /// needs to handle the call through its `noSuchMethod` handler.
  bool needsNoSuchMethodHandling(Selector selector, covariant World world);
}

/// A mutable [SelectorConstraints] used in [WorldBuilder].
abstract class UniverseSelectorConstraints extends SelectorConstraints {
  /// Adds [constraint] to these selector constraints. Return `true` if the set
  /// of potential receivers expanded due to the new constraint.
  bool addReceiverConstraint(covariant Object? constraint);
}

/// Strategy for computing the constraints on potential receivers of dynamic
/// call sites.
abstract class SelectorConstraintsStrategy {
  /// Create a [UniverseSelectorConstraints] to represent the global receiver
  /// constraints for dynamic call sites with [selector].
  UniverseSelectorConstraints createSelectorConstraints(
      Selector selector, Object? initialConstraint);

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
      Selector selector, Object? initialConstraint) {
    return StrongModeWorldConstraints()
      ..addReceiverConstraint(initialConstraint as StrongModeConstraint?);
  }

  @override
  bool appliedUnnamed(DynamicUse dynamicUse, MemberEntity member,
      covariant ResolutionWorldBuilder world) {
    Selector selector = dynamicUse.selector;
    final constraint = dynamicUse.receiverConstraint as StrongModeConstraint?;
    return selector.appliesUnnamed(member) &&
        (constraint == null ||
            constraint.canHit(member, selector.memberName, world));
  }
}

class StrongModeWorldConstraints extends UniverseSelectorConstraints {
  bool isAll = false;
  late Set<StrongModeConstraint> _constraints = {};

  @override
  bool canHit(MemberEntity element, Name name, World world) {
    if (isAll) return true;
    return _constraints.any((constraint) =>
        constraint.canHit(element, name, world as ResolutionWorldBuilder));
  }

  @override
  bool needsNoSuchMethodHandling(Selector selector, World world) {
    if (isAll) return true;
    return _constraints.any(
        (constraint) => constraint.needsNoSuchMethodHandling(selector, world));
  }

  @override
  bool addReceiverConstraint(StrongModeConstraint? constraint) {
    if (isAll) return false;
    if (constraint?.cls == null) {
      isAll = true;
      _constraints = const {};
      return true;
    }
    return _constraints.add(constraint!);
  }

  @override
  String toString() {
    if (isAll) {
      return '<all>';
    } else if (_constraints.isEmpty) {
      return '<none>';
    } else {
      return '<${_constraints.map((c) => c.cls).join(',')}>';
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
      cls = commonElements.jsLegacyJavaScriptObjectClass;
      relation = ClassRelation.subtype;
    }
    return StrongModeConstraint.internal(cls, relation);
  }

  const StrongModeConstraint.internal(this.cls, this.relation);

  bool needsNoSuchMethodHandling(Selector selector, World world) => true;

  bool canHit(MemberEntity element, Name name, ResolutionWorldBuilder world) {
    return world.isInheritedIn(element, cls, relation);
  }

  bool get isExact => relation == ClassRelation.exact;

  bool get isThis => relation == ClassRelation.thisExpression;

  String get className => cls.name;

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

abstract class WorldBuilder {
  final Map<Entity, Set<DartType>> staticTypeArgumentDependencies = {};

  final Map<Selector, Set<DartType>> dynamicTypeArgumentDependencies = {};

  final Set<TypeVariableType> typeVariableTypeLiterals = {};

  void _registerStaticTypeArgumentDependency(
      Entity element, List<DartType> typeArguments) {
    staticTypeArgumentDependencies
        .putIfAbsent(element, () => {})
        .addAll(typeArguments);
  }

  void _registerDynamicTypeArgumentDependency(
      Selector selector, List<DartType> typeArguments) {
    dynamicTypeArgumentDependencies
        .putIfAbsent(selector, () => {})
        .addAll(typeArguments);
  }

  void registerStaticInvocation(StaticUse staticUse) {
    final typeArguments = staticUse.typeArguments;
    if (typeArguments == null || typeArguments.isEmpty) return;
    _registerStaticTypeArgumentDependency(staticUse.element, typeArguments);
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
