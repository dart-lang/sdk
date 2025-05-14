// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/core_types.dart';

import 'factory_specializer.dart';

/// Replaces invocation of Set factory constructors with factories of
/// Wasm-specific classes.
///
///     new LinkedHashSet<E>() => new DefaultSet<E>()
class SetFactorySpecializer extends BaseSpecializer {
  final Procedure _linkedHashSetDefaultFactory;
  final Constructor _internalLinkedHashSetConstructor;

  SetFactorySpecializer(CoreTypes coreTypes)
      : _linkedHashSetDefaultFactory = coreTypes.index
            .getProcedure('dart:collection', 'LinkedHashSet', ''),
        _internalLinkedHashSetConstructor = coreTypes.index
            .getConstructor('dart:_compact_hash', 'DefaultSet', '') {
    transformers.addAll({_linkedHashSetDefaultFactory: transformLinkedHashSet});
  }

  TreeNode transformLinkedHashSet(StaticInvocation node) {
    final args = node.arguments;
    assert(args.positional.isEmpty);
    if (args.named.isEmpty) {
      return ConstructorInvocation(
        _internalLinkedHashSetConstructor,
        Arguments([], types: args.types),
      );
    }
    return node;
  }
}
