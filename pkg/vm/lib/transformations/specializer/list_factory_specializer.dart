// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.specializer.list_factory_specializer;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:vm/transformations/specializer/factory_specializer.dart';

/// Replaces invocation of List factory constructors with
/// factories of VM-specific classes.
///
/// new List() => new _GrowableList(0)
/// new List(n) => new _List(n)
/// new List.empty() => new _List.empty()
/// new List.empty(growable: false) => new _List.empty()
/// new List.empty(growable: true) => new _GrowableList.empty()
/// new List.filled(n, null, growable: true) => new _GrowableList(n)
/// new List.filled(n, x, growable: true) => new _GrowableList.filled(n, x)
/// new List.filled(n, null) => new _List(n)
/// new List.filled(n, x) => new _List.filled(n, x)
/// new List.generate(n, y) => new _GrowableList.generate(n, y)
/// new List.generate(n, y, growable: false) => new _List.generate(n, y)
///
class ListFactorySpecializer extends BaseSpecializer {
  final Procedure _defaultListFactory;
  final Procedure _listEmptyFactory;
  final Procedure _listFilledFactory;
  final Procedure _listGenerateFactory;
  final Procedure _growableListFactory;
  final Procedure _growableListEmptyFactory;
  final Procedure _growableListFilledFactory;
  final Procedure _growableListGenerateFactory;
  final Procedure _fixedListFactory;
  final Procedure _fixedListEmptyFactory;
  final Procedure _fixedListFilledFactory;
  final Procedure _fixedListGenerateFactory;

  ListFactorySpecializer(CoreTypes coreTypes)
      : _defaultListFactory =
            coreTypes.index.getMember('dart:core', 'List', ''),
        _listEmptyFactory =
            coreTypes.index.getMember('dart:core', 'List', 'empty'),
        _listFilledFactory =
            coreTypes.index.getMember('dart:core', 'List', 'filled'),
        _listGenerateFactory =
            coreTypes.index.getMember('dart:core', 'List', 'generate'),
        _growableListFactory =
            coreTypes.index.getMember('dart:core', '_GrowableList', ''),
        _growableListEmptyFactory =
            coreTypes.index.getMember('dart:core', '_GrowableList', 'empty'),
        _growableListFilledFactory =
            coreTypes.index.getMember('dart:core', '_GrowableList', 'filled'),
        _growableListGenerateFactory =
            coreTypes.index.getMember('dart:core', '_GrowableList', 'generate'),
        _fixedListFactory = coreTypes.index.getMember('dart:core', '_List', ''),
        _fixedListEmptyFactory =
            coreTypes.index.getMember('dart:core', '_List', 'empty'),
        _fixedListFilledFactory =
            coreTypes.index.getMember('dart:core', '_List', 'filled'),
        _fixedListGenerateFactory =
            coreTypes.index.getMember('dart:core', '_List', 'generate') {
    assert(_defaultListFactory.isFactory);
    assert(_listEmptyFactory.isFactory);
    assert(_listFilledFactory.isFactory);
    assert(_listGenerateFactory.isFactory);
    assert(_growableListFactory.isFactory);
    assert(_growableListEmptyFactory.isFactory);
    assert(_growableListFilledFactory.isFactory);
    assert(_growableListGenerateFactory.isFactory);
    assert(_fixedListFactory.isFactory);
    assert(_fixedListEmptyFactory.isFactory);
    assert(_fixedListFilledFactory.isFactory);
    assert(_fixedListGenerateFactory.isFactory);
    transformers.addAll({
      _defaultListFactory: transformDefaultFactory,
      _listEmptyFactory: transformListEmptyFactory,
      _listFilledFactory: transformListFilledFactory,
      _listGenerateFactory: transformListGeneratorFactory,
    });
  }

  TreeNode transformDefaultFactory(StaticInvocation node) {
    final args = node.arguments;
    if (args.positional.isEmpty) {
      return StaticInvocation(_growableListFactory,
          Arguments([new IntLiteral(0)], types: args.types))
        ..fileOffset = node.fileOffset;
    } else {
      return StaticInvocation(_fixedListFactory, args)
        ..fileOffset = node.fileOffset;
    }
  }

  TreeNode transformListEmptyFactory(StaticInvocation node) {
    final args = node.arguments;
    assert(args.positional.length == 0);
    final bool growable = _getConstantOptionalArgument(args, 'growable', false);
    if (growable == null) {
      return node;
    }
    if (growable) {
      return StaticInvocation(
          _growableListEmptyFactory, Arguments([], types: args.types))
        ..fileOffset = node.fileOffset;
    } else {
      return StaticInvocation(
          _fixedListEmptyFactory, Arguments([], types: args.types))
        ..fileOffset = node.fileOffset;
    }
  }

  TreeNode transformListFilledFactory(StaticInvocation node) {
    final args = node.arguments;
    assert(args.positional.length == 2);
    final length = args.positional[0];
    final fill = args.positional[1];
    final fillingWithNull = fill is NullLiteral ||
        (fill is ConstantExpression && fill.constant is NullConstant);
    final bool growable = _getConstantOptionalArgument(args, 'growable', false);
    if (growable == null) {
      return node;
    }
    if (growable) {
      if (fillingWithNull) {
        return StaticInvocation(
            _growableListFactory, Arguments([length], types: args.types))
          ..fileOffset = node.fileOffset;
      } else {
        return StaticInvocation(_growableListFilledFactory,
            Arguments([length, fill], types: args.types))
          ..fileOffset = node.fileOffset;
      }
    } else {
      if (fillingWithNull) {
        return StaticInvocation(
            _fixedListFactory, Arguments([length], types: args.types))
          ..fileOffset = node.fileOffset;
      } else {
        return StaticInvocation(_fixedListFilledFactory,
            Arguments([length, fill], types: args.types))
          ..fileOffset = node.fileOffset;
      }
    }
  }

  TreeNode transformListGeneratorFactory(StaticInvocation node) {
    final args = node.arguments;
    assert(args.positional.length == 2);
    final length = args.positional[0];
    final generator = args.positional[1];
    final bool growable = _getConstantOptionalArgument(args, 'growable', true);
    if (growable == null) {
      return node;
    }
    if (growable) {
      return StaticInvocation(_growableListGenerateFactory,
          Arguments([length, generator], types: args.types))
        ..fileOffset = node.fileOffset;
    } else {
      return StaticInvocation(_fixedListGenerateFactory,
          Arguments([length, generator], types: args.types))
        ..fileOffset = node.fileOffset;
    }
  }

  /// Returns constant value of the only optional argument in [args],
  /// or null if it is not a constant. Returns [defaultValue] if optional
  /// argument is not passed. Argument is asserted to have the given [name].
  bool /*?*/ _getConstantOptionalArgument(
      Arguments args, String name, bool defaultValue) {
    if (args.named.isEmpty) {
      return defaultValue;
    }
    final namedArg = args.named.single;
    assert(namedArg.name == name);
    final value = namedArg.value;
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
}
