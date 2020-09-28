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
  // Populated in constructors of subclasses.
  final Map<Member, SpecializerTransformer> transformers = {};
}

class FactorySpecializer extends BaseSpecializer {
  final ListFactorySpecializer _listFactorySpecializer;
  final SetFactorySpecializer _setFactorySpecializer;
  final MapFactorySpecializer _mapFactorySpecializer;

  FactorySpecializer(CoreTypes coreTypes)
      : _listFactorySpecializer = ListFactorySpecializer(coreTypes),
        _setFactorySpecializer = SetFactorySpecializer(coreTypes),
        _mapFactorySpecializer = MapFactorySpecializer(coreTypes) {
    transformers.addAll(_listFactorySpecializer.transformers);
    transformers.addAll(_setFactorySpecializer.transformers);
    transformers.addAll(_mapFactorySpecializer.transformers);
  }

  TreeNode transformStaticInvocation(StaticInvocation invocation) {
    final target = invocation.target;
    if (target == null) {
      return invocation;
    }

    final transformer = transformers[target];
    if (transformer != null) {
      return transformer(invocation);
    }
    return invocation;
  }
}
