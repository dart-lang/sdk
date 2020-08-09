// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.specializer.factory_specializer;

import 'package:kernel/kernel.dart';
import 'package:kernel/core_types.dart';
import 'package:vm/transformations/specializer/list_factory_specializer.dart';
import 'package:vm/transformations/specializer/map_factory_specializer.dart';
import 'package:vm/transformations/specializer/set_factory_specializer.dart';

typedef SpecializerTransformer = TreeNode Function(StaticInvocation node);

abstract class BaseSpecializer {
  final Map<Member, SpecializerTransformer> transformers = {};
  Map<Member, SpecializerTransformer> get transformersMap => transformers;
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
  Map<Member, SpecializerTransformer> get transformersMap {
    final transformers = <Member, SpecializerTransformer>{};
    transformers.addAll(_listFactorySpecializer.transformersMap);
    transformers.addAll(_setFactorySpecializer.transformersMap);
    transformers.addAll(_mapFactorySpecializer.transformersMap);
    return transformers;
  }

  TreeNode transformStaticInvocation(StaticInvocation invocation) {
    if (invocation == null) {
      return invocation;
    }
    final target = invocation.target;
    if (target == null) {
      return invocation;
    }

    final transformer = transformersMap[target];
    if (transformer != null) {
      return transformer(invocation);
    }
    return invocation;
  }
}
