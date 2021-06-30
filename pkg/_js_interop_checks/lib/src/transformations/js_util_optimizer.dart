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
  final Procedure _callMethodTarget;
  final List<Procedure> _callMethodUncheckedTargets;
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
  final Procedure _listEmptyFactory;

  final CoreTypes _coreTypes;
  final StatefulStaticTypeContext _staticTypeContext;

  JsUtilOptimizer(this._coreTypes, ClassHierarchy hierarchy)
      : _jsTarget =
            _coreTypes.index.getTopLevelMember('dart:_foreign_helper', 'JS'),
        _callMethodTarget =
            _coreTypes.index.getTopLevelMember('dart:js_util', 'callMethod'),
        _callMethodUncheckedTargets = List<Procedure>.generate(
            5,
            (i) => _coreTypes.index
                .getTopLevelMember('dart:js_util', '_callMethodUnchecked$i')),
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
        _listEmptyFactory =
            _coreTypes.index.getMember('dart:core', 'List', 'empty'),
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
  /// Lowers `callMethod` to `_callMethodUncheckedN` when the number of given
  /// arguments is 0-4 and all arguments are guaranteed to be interop allowed.
  @override
  visitStaticInvocation(StaticInvocation node) {
    if (node.target == _getPropertyTarget) {
      node = _lowerGetProperty(node);
    } else if (node.target == _setPropertyTarget) {
      node = _lowerSetProperty(node);
    } else if (node.target == _callMethodTarget) {
      node = _lowerCallMethod(node);
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
  ///
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

  /// Lowers the given js_util `callMethod` call to `_callMethodUncheckedN`
  /// when the additional validation checks on the arguments can be elided.
  ///
  /// Calls will be lowered when using a List literal or constant list with 0-4
  /// elements for the `callMethod` arguments, or the `List.empty()` factory.
  /// Removing the checks allows further inlining by the compilers.
  StaticInvocation _lowerCallMethod(StaticInvocation node) {
    Arguments arguments = node.arguments;
    assert(arguments.types.isEmpty);
    assert(arguments.positional.length == 3);
    assert(arguments.named.isEmpty);

    // Lower List.empty factory call.
    var argumentsList = arguments.positional.last;
    if (argumentsList is StaticInvocation &&
        argumentsList.target == _listEmptyFactory) {
      return _createNewCallMethodNode([], arguments, node.fileOffset);
    }

    // Lower other kinds of Lists.
    var callMethodArguments;
    var entryType;
    if (argumentsList is ListLiteral) {
      if (argumentsList.expressions.length >=
          _callMethodUncheckedTargets.length) {
        return node;
      }
      callMethodArguments = argumentsList.expressions;
      entryType = argumentsList.typeArgument;
    } else if (argumentsList is ConstantExpression &&
        argumentsList.constant is ListConstant) {
      var argumentsListConstant = argumentsList.constant as ListConstant;
      if (argumentsListConstant.entries.length >=
          _callMethodUncheckedTargets.length) {
        return node;
      }
      callMethodArguments = argumentsListConstant.entries
          .map((constant) => ConstantExpression(
              constant, constant.getType(_staticTypeContext)))
          .toList();
      entryType = argumentsListConstant.typeArgument;
    } else {
      // Skip lowering any other type of List.
      return node;
    }

    // Check the overall List entry type, then verify each argument if needed.
    if (!_allowedInteropType(entryType)) {
      for (var argument in callMethodArguments) {
        if (!_allowedInterop(argument)) {
          return node;
        }
      }
    }

    return _createNewCallMethodNode(
        callMethodArguments, arguments, node.fileOffset);
  }

  /// Creates a new StaticInvocation node for `_callMethodUncheckedN` with the
  /// given 0-4 arguments.
  StaticInvocation _createNewCallMethodNode(
      List<Expression> callMethodArguments,
      Arguments arguments,
      int nodeFileOffset) {
    assert(callMethodArguments.length <= 4);
    return StaticInvocation(
        _callMethodUncheckedTargets[callMethodArguments.length],
        Arguments(
          [
            arguments.positional[0],
            arguments.positional[1],
            ...callMethodArguments
          ],
          types: [],
        )..fileOffset = arguments.fileOffset)
      ..fileOffset = nodeFileOffset;
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

    return _allowedInteropType(node.getStaticType(_staticTypeContext));
  }

  /// Returns whether the given DartType is guaranteed to be not a function
  /// and therefore allowed to interop with JS.
  bool _allowedInteropType(DartType type) {
    if (type is InterfaceType) {
      return type.classNode != _coreTypes.functionClass &&
          type.classNode != _coreTypes.objectClass;
    } else {
      // Only other DartType guaranteed to not be a function.
      return type is NullType;
    }
  }
}
