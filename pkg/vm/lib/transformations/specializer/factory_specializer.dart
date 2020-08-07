// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.specializer.factory_specializer;

import 'package:kernel/kernel.dart';
import 'package:kernel/core_types.dart';
import 'package:vm/transformations/specializer/list_factory_specializer.dart';
import 'package:vm/transformations/specializer/map_factory_specializer.dart';
import 'package:vm/transformations/specializer/set_factory_specializer.dart';

typedef SpecializerTransformer<T extends TreeNode> = TreeNode Function(T node);

abstract class BaseSpecializer {
  /// Map from Memeber to Transformer
  Map<Member, SpecializerTransformer> get transformersMap;
}

class FactorySpecializer extends BaseSpecializer {
  final ListFactorySpecializer _listFactorySpecializer;
  final SetFactorySpecializer _setFactorySpecializer;
  final MapFactorySpecializer _mapFactorySpecializer;

  FactorySpecializer(CoreTypes coreTypes)
      : _listFactorySpecializer = ListFactorySpecializer(coreTypes),
        _setFactorySpecializer = SetFactorySpecializer(coreTypes),
        _mapFactorySpecializer = MapFactorySpecializer(coreTypes);

  @override
  Map<Member, SpecializerTransformer<TreeNode>> get transformersMap {
    final transformers = <Member, SpecializerTransformer>{};
    transformers.addAll(_listFactorySpecializer.transformersMap);
    transformers.addAll(_setFactorySpecializer.transformersMap);
    transformers.addAll(_mapFactorySpecializer.transformersMap);
    return transformers;
  }

  TreeNode specialize(StaticInvocation invocation) {
    final target = invocation.target;
    if (target == null) {
      return invocation;
    }

    if (!transformersMap.containsKey(target)) {
      return invocation;
    }

    final result = transformersMap[target](invocation);
    return result ?? invocation;
  }
}
