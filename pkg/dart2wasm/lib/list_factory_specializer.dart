// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;

/// Replaces invocation of `List` factory constructors with factories of
/// dart2wasm-specific classes.
///
/// ```
/// List.empty() => _List.empty()
/// List.empty(growable: false) => _List.empty()
/// List.empty(growable: true) => _GrowableList.empty()
/// List.filled(n, null, growable: true) => _GrowableList(n)
/// List.filled(n, x, growable: true) => _GrowableList.filled(n, x)
/// List.filled(n, null) => _List(n)
/// List.filled(n, x) => _List.filled(n, x)
/// List.generate(n, y) => _GrowableList.generate(n, y)
/// List.generate(n, y, growable: false) => _List.generate(n, y)
/// ```
class ListFactorySpecializer {
  final Map<Member, TreeNode Function(StaticInvocation node)> _transformers =
      {};

  final Procedure _fixedListEmptyFactory;
  final Procedure _fixedListFactory;
  final Procedure _fixedListFilledFactory;
  final Procedure _fixedListGenerateFactory;
  final Procedure _growableListEmptyFactory;
  final Procedure _growableListFactory;
  final Procedure _growableListFilledFactory;
  final Procedure _growableListGenerateFactory;
  final Procedure _listEmptyFactory;
  final Procedure _listFilledFactory;
  final Procedure _listGenerateFactory;

  ListFactorySpecializer(CoreTypes coreTypes)
      : _listEmptyFactory =
            coreTypes.index.getProcedure('dart:core', 'List', 'empty'),
        _listFilledFactory =
            coreTypes.index.getProcedure('dart:core', 'List', 'filled'),
        _listGenerateFactory =
            coreTypes.index.getProcedure('dart:core', 'List', 'generate'),
        _growableListFactory =
            coreTypes.index.getProcedure('dart:core', '_GrowableList', ''),
        _growableListEmptyFactory =
            coreTypes.index.getProcedure('dart:core', '_GrowableList', 'empty'),
        _growableListFilledFactory = coreTypes.index
            .getProcedure('dart:core', '_GrowableList', 'filled'),
        _growableListGenerateFactory = coreTypes.index
            .getProcedure('dart:core', '_GrowableList', 'generate'),
        _fixedListFactory =
            coreTypes.index.getProcedure('dart:core', '_List', ''),
        _fixedListEmptyFactory =
            coreTypes.index.getProcedure('dart:core', '_List', 'empty'),
        _fixedListFilledFactory =
            coreTypes.index.getProcedure('dart:core', '_List', 'filled'),
        _fixedListGenerateFactory =
            coreTypes.index.getProcedure('dart:core', '_List', 'generate') {
    _transformers[_listFilledFactory] = _transformListFilledFactory;
    _transformers[_listEmptyFactory] = _transformListEmptyFactory;
    _transformers[_listGenerateFactory] = _transformListGenerateFactory;
  }

  TreeNode transformStaticInvocation(StaticInvocation invocation) {
    final target = invocation.target;
    final transformer = _transformers[target];
    if (transformer != null) {
      return transformer(invocation);
    }
    return invocation;
  }

  // List.filled(n, null, growable: true) => _GrowableList(n)
  // List.filled(n, x, growable: true) => _GrowableList.filled(n, x)
  // List.filled(n, null) => _List(n)
  // List.filled(n, x) => _List.filled(n, x)
  TreeNode _transformListFilledFactory(StaticInvocation node) {
    final args = node.arguments;
    assert(args.positional.length == 2);
    final length = args.positional[0];
    final fill = args.positional[1];
    final fillingWithNull = _isNullConstant(fill);

    // Null when the argument is not a constant or a `bool` literal, e.g.
    // `List.filled(..., growable: f())`.
    final bool? growable =
        _getConstantOptionalArgument(args, 'growable', false);

    if (growable == null) {
      return node;
    }

    if (growable) {
      if (fillingWithNull) {
        // List.filled(n, null, growable: true) => _GrowableList(n)
        return StaticInvocation(
            _growableListFactory, Arguments([length], types: args.types))
          ..fileOffset = node.fileOffset;
      } else {
        // List.filled(n, x, growable: true) => _GrowableList.filled(n, x)
        return StaticInvocation(_growableListFilledFactory,
            Arguments([length, fill], types: args.types))
          ..fileOffset = node.fileOffset;
      }
    } else {
      if (fillingWithNull) {
        // List.filled(n, null, growable: false) => _List(n)
        return StaticInvocation(
            _fixedListFactory, Arguments([length], types: args.types))
          ..fileOffset = node.fileOffset;
      } else {
        // List.filled(n, x, growable: false) => _List.filled(n, x)
        return StaticInvocation(_fixedListFilledFactory,
            Arguments([length, fill], types: args.types))
          ..fileOffset = node.fileOffset;
      }
    }
  }

  // List.empty() => _List.empty()
  // List.empty(growable: false) => _List.empty()
  // List.empty(growable: true) => _GrowableList.empty()
  TreeNode _transformListEmptyFactory(StaticInvocation node) {
    final args = node.arguments;
    assert(args.positional.isEmpty);
    final bool? growable =
        _getConstantOptionalArgument(args, 'growable', false);
    if (growable == null) {
      return node;
    }
    if (growable) {
      // List.empty(growable: true) => _GrowableList.empty()
      return StaticInvocation(
          _growableListEmptyFactory, Arguments([], types: args.types))
        ..fileOffset = node.fileOffset;
    } else {
      // List.empty() => _List.empty()
      // List.empty(growable: false) => _List.empty()
      return StaticInvocation(
          _fixedListEmptyFactory, Arguments([], types: args.types))
        ..fileOffset = node.fileOffset;
    }
  }

  // List.generate(n, y) => _GrowableList.generate(n, y)
  // List.generate(n, y, growable: false) => _List.generate(n, y)
  TreeNode _transformListGenerateFactory(StaticInvocation node) {
    final args = node.arguments;
    assert(args.positional.length == 2);
    final length = args.positional[0];
    final generator = args.positional[1];
    final bool? growable = _getConstantOptionalArgument(args, 'growable', true);
    if (growable == null) {
      return node;
    }
    if (growable) {
      // List.generate(n, y) => _GrowableList.generate(n, y)
      return StaticInvocation(_growableListGenerateFactory,
          Arguments([length, generator], types: args.types))
        ..fileOffset = node.fileOffset;
    } else {
      // List.generate(n, y, growable: false) => _List.generate(n, y)
      return StaticInvocation(_fixedListGenerateFactory,
          Arguments([length, generator], types: args.types))
        ..fileOffset = node.fileOffset;
    }
  }
}

/// Returns constant value of the only optional argument in [args], or null
/// if it is not a constant. Returns [defaultValue] if optional argument is
/// not passed. Argument is asserted to have the given [name].
bool? _getConstantOptionalArgument(
    Arguments args, String name, bool defaultValue) {
  if (args.named.isEmpty) {
    return defaultValue;
  }
  final namedArg = args.named.single;
  assert(namedArg.name == name);
  final value = _unwrapFinalVariableGet(namedArg.value);
  if (value is BoolLiteral) {
    return value.value;
  } else if (value is ConstantExpression) {
    final constant = value.constant;
    if (constant is BoolConstant) {
      return constant.value;
    }
  }
  return null;
}

bool _isNullConstant(Expression value) {
  value = _unwrapFinalVariableGet(value);
  return value is NullLiteral ||
      (value is ConstantExpression && value.constant is NullConstant);
}

// Front-end can create extra temporary variables ("Let v = e, call(v)") to
// hoist expressions when rearraning named parameters. Unwrap such variables
// and return their initializers.
Expression _unwrapFinalVariableGet(Expression expr) {
  if (expr is VariableGet) {
    final variable = expr.variable;
    if (variable.isFinal) {
      final initializer = variable.initializer;
      if (initializer != null) {
        return initializer;
      }
    }
  }
  return expr;
}
