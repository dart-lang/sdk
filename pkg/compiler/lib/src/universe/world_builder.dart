// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library world_builder;

import 'dart:collection';

import '../common.dart';
import '../common/names.dart' show Identifiers;
import '../common/resolution.dart' show Resolution;
import '../common_elements.dart';
import '../constants/constant_system.dart';
import '../constants/values.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/resolution_types.dart';
import '../elements/types.dart';
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../js_backend/backend_usage.dart' show BackendUsageBuilder;
import '../js_backend/constant_handler_javascript.dart'
    show JavaScriptConstantCompiler;
import '../js_backend/interceptor_data.dart' show InterceptorDataBuilder;
import '../js_backend/native_data.dart' show NativeBasicData, NativeDataBuilder;
import '../js_backend/runtime_types.dart';
import '../kernel/element_map_impl.dart';
import '../native/enqueue.dart' show NativeResolutionEnqueuer;
import '../options.dart';
import '../universe/class_set.dart';
import '../util/enumset.dart';
import '../util/util.dart';
import '../world.dart' show World, ClosedWorld, ClosedWorldImpl, OpenWorld;
import 'selector.dart' show Selector;
import 'use.dart'
    show
        ConstantUse,
        ConstantUseKind,
        DynamicUse,
        DynamicUseKind,
        StaticUse,
        StaticUseKind;

part 'codegen_world_builder.dart';
part 'element_world_builder.dart';
part 'member_usage.dart';
part 'resolution_world_builder.dart';

/// The known constraint on receiver for a dynamic call site.
///
/// This can for instance be used to constrain this dynamic call to `foo` to
/// 'receivers of the exact instance `Bar`':
///
///     class Bar {
///        void foo() {}
///     }
///     main() => new Bar().foo();
///
abstract class ReceiverConstraint {
  /// Returns whether [element] is a potential target when being
  /// invoked on a receiver with this constraint. [selector] is used to ensure
  /// library privacy is taken into account.
  bool canHit(MemberEntity element, Selector selector, covariant World world);

  /// Returns whether this [TypeMask] applied to [selector] can hit a
  /// [noSuchMethod].
  bool needsNoSuchMethodHandling(Selector selector, covariant World world);
}

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
  /// Returns `true` if [selector] applies to [element] under these constraints
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
  bool applies(MemberEntity element, Selector selector, covariant World world);

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
  bool addReceiverConstraint(covariant ReceiverConstraint constraint);
}

/// Strategy for computing the constraints on potential receivers of dynamic
/// call sites.
abstract class SelectorConstraintsStrategy {
  /// Create a [UniverseSelectorConstraints] to represent the global receiver
  /// constraints for dynamic call sites with [selector].
  UniverseSelectorConstraints createSelectorConstraints(Selector selector);
}

class OpenWorldStrategy implements SelectorConstraintsStrategy {
  const OpenWorldStrategy();

  OpenWorldConstraints createSelectorConstraints(Selector selector) {
    return new OpenWorldConstraints();
  }
}

class OpenWorldConstraints extends UniverseSelectorConstraints {
  bool isAll = false;

  @override
  bool applies(MemberEntity element, Selector selector, World world) => isAll;

  @override
  bool needsNoSuchMethodHandling(Selector selector, World world) => isAll;

  @override
  bool addReceiverConstraint(ReceiverConstraint constraint) {
    if (isAll) return false;
    isAll = true;
    return true;
  }

  String toString() {
    if (isAll) {
      return '<all>';
    } else {
      return '<none>';
    }
  }
}

/// The [WorldBuilder] is an auxiliary class used in the process of computing
/// the [ClosedWorld].
// TODO(johnniwinther): Move common implementation to a [WorldBuilderBase] when
// universes and worlds have been unified.
abstract class WorldBuilder {
  /// All directly instantiated classes, that is, classes with a generative
  /// constructor that has been called directly and not only through a
  /// super-call.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<ClassEntity> get directlyInstantiatedClasses;

  /// All types that are checked either through is, as or checked mode checks.
  Iterable<DartType> get isChecks;

  /// All directly instantiated types, that is, the types of the directly
  /// instantiated classes.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<InterfaceType> get instantiatedTypes;

  /// Registers that [type] is checked in this world builder. The unaliased type
  /// is returned.
  void registerIsCheck(DartType type);
}
