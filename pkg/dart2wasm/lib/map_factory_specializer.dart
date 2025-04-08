// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import 'factory_specializer.dart';

/// Replaces invocation of Map factory constructors with factories of
/// Wasm-specific classes.
///
///     new LinkedHashMap<K, V>() => new DefaultMap<K, V>()
class MapFactorySpecializer extends BaseSpecializer {
  final Procedure _linkedHashMapDefaultFactory;
  final Constructor _internalLinkedHashMapConstructor;

  MapFactorySpecializer(CoreTypes coreTypes)
      : _linkedHashMapDefaultFactory = coreTypes.index
            .getProcedure('dart:collection', 'LinkedHashMap', ''),
        _internalLinkedHashMapConstructor = coreTypes.index
            .getConstructor('dart:_compact_hash', 'DefaultMap', '') {
    transformers.addAll({_linkedHashMapDefaultFactory: transformLinkedHashMap});
  }

  TreeNode transformLinkedHashMap(StaticInvocation node) {
    final args = node.arguments;
    if (args.named.isEmpty) {
      return ConstructorInvocation(
        _internalLinkedHashMapConstructor,
        Arguments([], types: args.types),
      )..fileOffset = node.fileOffset;
    }

    return node;
  }
}
