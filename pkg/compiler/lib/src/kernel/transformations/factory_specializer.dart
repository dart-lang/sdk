// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart';
import 'list_factory_specializer.dart';

typedef SpecializerTransformer = TreeNode Function(
    StaticInvocation node, Member contextMember);

abstract class BaseSpecializer {
  // Populated in constructors of subclasses.
  final Map<Member, SpecializerTransformer> transformers = {};
}

class FactorySpecializer extends BaseSpecializer {
  final ListFactorySpecializer _listFactorySpecializer;

  FactorySpecializer(CoreTypes coreTypes, ClassHierarchy hierarchy)
      : _listFactorySpecializer = ListFactorySpecializer(coreTypes, hierarchy) {
    transformers.addAll(_listFactorySpecializer.transformers);
  }

  TreeNode transformStaticInvocation(
      StaticInvocation invocation, Member contextMember) {
    final target = invocation.target;
    if (target == null) {
      return invocation;
    }

    final transformer = transformers[target];
    if (transformer != null) {
      return transformer(invocation, contextMember);
    }
    return invocation;
  }
}
