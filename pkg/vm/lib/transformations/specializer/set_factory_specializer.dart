// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.specializer.set_factory_specializer;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/core_types.dart';
import 'package:vm/transformations/specializer/factory_specializer.dart';

/// Replaces invocation of Map factory constructors with
/// factories of VM-specific classes.
/// new Set() => new _CompactLinkedHashSet<K, V>()
/// new LinkedHashSet<E>() => new _CompactLinkedHashSet<E>()
class SetFactorySpecializer extends BaseSpecializer {
  final Procedure _defaultSetFactory;
  final Procedure _linkedHashSetDefaultFactory;
  final Constructor _compactLinkedHashSetConstructor;

  SetFactorySpecializer(CoreTypes coreTypes)
      : _defaultSetFactory = assertNotNull(
          coreTypes.index.getMember(
            'dart:core',
            'Set',
            '',
          ),
        ),
        _linkedHashSetDefaultFactory = assertNotNull(
          coreTypes.index.getMember(
            'dart:collection',
            'LinkedHashSet',
            '',
          ),
        ),
        _compactLinkedHashSetConstructor = assertNotNull(
          coreTypes.index.getMember(
            'dart:collection',
            '_CompactLinkedHashSet',
            '',
          ),
        );

  static T assertNotNull<T>(T t) {
    assert(t != null);
    return t;
  }

  TreeNode transformDefaultSetFactory(TreeNode origin) {
    if (origin is! StaticInvocation) {
      return origin;
    }
    final node = origin as StaticInvocation;
    final args = node.arguments;
    assert(args.positional.isEmpty);
    return ConstructorInvocation(
      _compactLinkedHashSetConstructor,
      Arguments([], types: args.types),
    )..fileOffset = node.fileOffset;
  }

  TreeNode transformLinkedHashSet(TreeNode origin) {
    if (origin is! StaticInvocation) {
      return origin;
    }
    final node = origin as StaticInvocation;
    final args = node.arguments;
    assert(args.positional.isEmpty);
    if (args.named.isEmpty) {
      return ConstructorInvocation(
        _compactLinkedHashSetConstructor,
        Arguments([], types: args.types),
      );
    }
    return origin;
  }

  @override
  Map<Member, SpecializerTransformer> get transformersMap => {
        _defaultSetFactory: transformDefaultSetFactory,
        _linkedHashSetDefaultFactory: transformLinkedHashSet,
      };
}
