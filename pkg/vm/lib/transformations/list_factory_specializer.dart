// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.list_factory_specializer;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;

/// Replaces new List() and new List(n) with VM-specific
/// new _GrowableList(0) and new _List(n).
void transformLibraries(List<Library> libraries, CoreTypes coreTypes) {
  final transformer = new _ListFactorySpecializer(coreTypes);
  libraries.forEach(transformer.visitLibrary);
}

class _ListFactorySpecializer extends Transformer {
  final Procedure _listFactory;
  final Procedure _growableListFactory;
  final Procedure _fixedListFactory;

  _ListFactorySpecializer(CoreTypes coreTypes)
      : _listFactory = coreTypes.index.getMember('dart:core', 'List', ''),
        _growableListFactory =
            coreTypes.index.getMember('dart:core', '_GrowableList', ''),
        _fixedListFactory =
            coreTypes.index.getMember('dart:core', '_List', '') {
    assert(_listFactory.isFactory);
    assert(_growableListFactory.isFactory);
    assert(_fixedListFactory.isFactory);
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    super.visitStaticInvocation(node);

    if (node.target == _listFactory) {
      if (node.arguments.positional.isEmpty) {
        return new StaticInvocation(_growableListFactory,
            new Arguments([new IntLiteral(0)], types: node.arguments.types))
          ..parent = node.parent
          ..fileOffset = node.fileOffset;
      } else {
        return new StaticInvocation(_fixedListFactory, node.arguments)
          ..parent = node.parent
          ..fileOffset = node.fileOffset;
      }
    }

    return node;
  }
}
