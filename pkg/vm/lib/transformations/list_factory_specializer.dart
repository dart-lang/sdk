// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.list_factory_specializer;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;

/// Replaces invocation of List factory constructors with
/// factories of VM-specific classes.
///
/// new List() => new _GrowableList(0)
/// new List(n) => new _List(n)
/// new List.filled(n, null, growable: true) => new _GrowableList(n)
/// new List.filled(n, null) => new _List(n)
///
void transformLibraries(List<Library> libraries, CoreTypes coreTypes) {
  final transformer = new _ListFactorySpecializer(coreTypes);
  libraries.forEach(transformer.visitLibrary);
}

class _ListFactorySpecializer extends Transformer {
  final Procedure _defaultListFactory;
  final Procedure _listFilledFactory;
  final Procedure _growableListFactory;
  final Procedure _fixedListFactory;

  _ListFactorySpecializer(CoreTypes coreTypes)
      : _defaultListFactory =
            coreTypes.index.getMember('dart:core', 'List', ''),
        _listFilledFactory =
            coreTypes.index.getMember('dart:core', 'List', 'filled'),
        _growableListFactory =
            coreTypes.index.getMember('dart:core', '_GrowableList', ''),
        _fixedListFactory =
            coreTypes.index.getMember('dart:core', '_List', '') {
    assert(_defaultListFactory.isFactory);
    assert(_listFilledFactory.isFactory);
    assert(_growableListFactory.isFactory);
    assert(_fixedListFactory.isFactory);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    super.visitStaticInvocation(node);

    final target = node.target;
    if (target == _defaultListFactory) {
      final args = node.arguments;
      if (args.positional.isEmpty) {
        return StaticInvocation(_growableListFactory,
            Arguments([new IntLiteral(0)], types: args.types))
          ..fileOffset = node.fileOffset;
      } else {
        return StaticInvocation(_fixedListFactory, args)
          ..fileOffset = node.fileOffset;
      }
    } else if (target == _listFilledFactory) {
      final args = node.arguments;
      assert(args.positional.length == 2);
      final length = args.positional[0];
      final fill = args.positional[1];
      if (fill is! NullLiteral &&
          !(fill is ConstantExpression && fill.constant is NullConstant)) {
        return node;
      }
      bool growable;
      if (args.named.isEmpty) {
        growable = false;
      } else {
        final namedArg = args.named.single;
        assert(namedArg.name == 'growable');
        final value = namedArg.value;
        if (value is BoolLiteral) {
          growable = value.value;
        } else if (value is ConstantExpression) {
          final constant = value.constant;
          if (constant is BoolConstant) {
            growable = constant.value;
          } else {
            return node;
          }
        } else {
          return node;
        }
      }
      if (growable) {
        return StaticInvocation(
            _growableListFactory, Arguments([length], types: args.types))
          ..fileOffset = node.fileOffset;
      } else {
        return StaticInvocation(
            _fixedListFactory, Arguments([length], types: args.types))
          ..fileOffset = node.fileOffset;
      }
    }

    return node;
  }
}
