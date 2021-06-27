// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';
import 'package:kernel/kernel.dart';

/// Replaces js_util methods with inline calls to foreign_helper JS which
/// emits the code as a JavaScript code fragment.
class JsUtilOptimizer extends Transformer {
  final Procedure _jsTarget;
  final Procedure _getPropertyTarget;
  final Procedure _setPropertyTarget;
  final Procedure _setPropertyUncheckedTarget;

  /// Dynamic members in js_util that interop allowed.
  static final Iterable<String> _allowedInteropJsUtilMembers = <String>[
    'callConstructor',
    'callMethod',
    'getProperty',
    'jsify',
    'newObject',
    'setProperty'
  ];
  final Iterable<Procedure> _allowedInteropJsUtilTargets;
  final Procedure _allowInteropTarget;

  final CoreTypes _coreTypes;
  final StatefulStaticTypeContext _staticTypeContext;

  JsUtilOptimizer(this._coreTypes, ClassHierarchy hierarchy)
      : _jsTarget =
            _coreTypes.index.getTopLevelMember('dart:_foreign_helper', 'JS'),
        _getPropertyTarget =
            _coreTypes.index.getTopLevelMember('dart:js_util', 'getProperty'),
        _setPropertyTarget =
            _coreTypes.index.getTopLevelMember('dart:js_util', 'setProperty'),
        _setPropertyUncheckedTarget = _coreTypes.index
            .getTopLevelMember('dart:js_util', '_setPropertyUnchecked'),
        _allowInteropTarget =
            _coreTypes.index.getTopLevelMember('dart:js', 'allowInterop'),
        _allowedInteropJsUtilTargets = _allowedInteropJsUtilMembers.map(
            (member) =>
                _coreTypes.index.getTopLevelMember('dart:js_util', member)),
        _staticTypeContext = StatefulStaticTypeContext.stacked(
            TypeEnvironment(_coreTypes, hierarchy)) {}

  @override
  visitLibrary(Library lib) {
    _staticTypeContext.enterLibrary(lib);
    lib.transformChildren(this);
    _staticTypeContext.leaveLibrary(lib);
    return lib;
  }

  @override
  defaultMember(Member node) {
    _staticTypeContext.enterMember(node);
    node.transformChildren(this);
    _staticTypeContext.leaveMember(node);
    return node;
  }

  /// Replaces js_util method calls with optimization when possible.
  ///
  /// Lowers `getProperty` for any argument type straight to JS fragment call.
  /// Lowers `setProperty` to `_setPropertyUnchecked` for values that are
  /// not Function type and guaranteed to be interop allowed.
  @override
  visitStaticInvocation(StaticInvocation node) {
    if (node.target == _getPropertyTarget) {
      node = _lowerGetProperty(node);
    } else if (node.target == _setPropertyTarget) {
      node = _lowerSetProperty(node);
    }
    node.transformChildren(this);
    return node;
  }

  /// Lowers the given js_util `getProperty` call to the foreign_helper JS call
  /// for any argument type. Lowers `getProperty(o, name)` to
  /// `JS('Object|Null', '#.#', o, name)`.
  StaticInvocation _lowerGetProperty(StaticInvocation node) {
    Arguments arguments = node.arguments;
    assert(arguments.types.isEmpty);
    assert(arguments.positional.length == 2);
    assert(arguments.named.isEmpty);
    return StaticInvocation(
        _jsTarget,
        Arguments(
          [
            StringLiteral("Object|Null"),
            StringLiteral("#.#"),
            ...arguments.positional
          ],
          // TODO(rileyporter): Copy type from getProperty when it's generic.
          types: [DynamicType()],
        )..fileOffset = arguments.fileOffset)
      ..fileOffset = node.fileOffset;
  }

  /// Lowers the given js_util `setProperty` call to `_setPropertyUnchecked`
  /// when the additional validation checks in `setProperty` can be elided.
  /// Removing the checks allows further inlining by the compilers.
  StaticInvocation _lowerSetProperty(StaticInvocation node) {
    Arguments arguments = node.arguments;
    assert(arguments.types.isEmpty);
    assert(arguments.positional.length == 3);
    assert(arguments.named.isEmpty);

    if (!_allowedInterop(arguments.positional.last)) {
      return node;
    }

    return StaticInvocation(_setPropertyUncheckedTarget, arguments)
      ..fileOffset = node.fileOffset;
  }

  /// Returns whether the given Expression is guaranteed to be allowed to
  /// interop with JS.
  ///
  /// Returns true when the node is guaranteed to be not a function:
  ///    - has a static DartType that is NullType or an InterfaceType that is
  ///      not Function or Object
  /// Also returns true for allowed method calls within the JavaScript domain:
  ///        - dart:_foreign_helper JS
  ///        - dart:js `allowInterop`
  ///        - dart:js_util and any of the `_allowedInteropJsUtilMembers`
  bool _allowedInterop(Expression node) {
    // TODO(rileyporter): Detect functions that have been wrapped at some point
    // with `allowInterop`
    if (node is StaticInvocation) {
      if (node.target == _allowInteropTarget) return true;
      if (node.target == _jsTarget) return true;
      if (_allowedInteropJsUtilTargets.contains(node.target)) return true;
    }

    var type = node.getStaticType(_staticTypeContext);
    if (type is InterfaceType) {
      return type.classNode != _coreTypes.functionClass &&
          type.classNode != _coreTypes.objectClass;
    } else {
      // Only other DartType guaranteed to not be a function.
      return type is NullType;
    }
  }
}
