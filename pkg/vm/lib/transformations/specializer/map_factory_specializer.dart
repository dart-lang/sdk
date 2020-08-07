// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.specializer.map_factory_specializer;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'dart:core';

import 'package:vm/transformations/specializer/factory_specializer.dart';

/// Replaces invocation of Map factory constructors with
/// factories of VM-specific classes.
/// new Map() => new _InternalLinkedHashMap<K, V>()
/// new LinkedHashMap<K, V>() => new _InternalLinkedHashMap<K, V>()
class MapFactorySpecializer extends BaseSpecializer {
  final Procedure _defaultMapFactory;
  final Procedure _linkedHashMapDefaultFactory;
  final Constructor _internalLinkedHashMapConstructor;

  MapFactorySpecializer(CoreTypes coreTypes)
      : _defaultMapFactory = assertNotNull(
          coreTypes.index.getMember(
            'dart:core',
            'Map',
            '',
          ),
        ),
        _linkedHashMapDefaultFactory = assertNotNull(
          coreTypes.index.getMember(
            'dart:collection',
            'LinkedHashMap',
            '',
          ),
        ),
        _internalLinkedHashMapConstructor = assertNotNull(
          coreTypes.index.getMember(
            'dart:collection',
            '_InternalLinkedHashMap',
            '',
          ),
        );

  static T assertNotNull<T>(T t) {
    assert(t != null);
    return t;
  }

  TreeNode transformDefaultMapFactory(TreeNode origin) {
    if (origin is! StaticInvocation) {
      return origin;
    }
    final node = origin as StaticInvocation;
    final args = node.arguments;
    assert(args.positional.length == 0);
    // new Map() => new _InternalLinkedHashMap<K, V>()
    return ConstructorInvocation(
      _internalLinkedHashMapConstructor,
      Arguments([], types: args.types),
    )..fileOffset = node.fileOffset;
  }

  TreeNode transformLinkedHashMap(TreeNode origin) {
    if (origin is! StaticInvocation) {
      return origin;
    }
    final node = origin as StaticInvocation;
    final args = node.arguments;
    if (args.named.isEmpty) {
      return ConstructorInvocation(
        _internalLinkedHashMapConstructor,
        Arguments([], types: args.types),
      )..fileOffset = node.fileOffset;
    }

    return origin;
  }

  @override
  Map<Member, SpecializerTransformer> get transformersMap => {
        _defaultMapFactory: transformDefaultMapFactory,
        _linkedHashMapDefaultFactory: transformLinkedHashMap,
      };
}
