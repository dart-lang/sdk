// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_algebra.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../js_backend/annotations.dart';
import 'impact.dart';
import 'scope.dart';

class ModularMemberData {
  final ScopeModel scopeModel;
  final ImpactBuilderData impactBuilderData;

  ModularMemberData(this.scopeModel, this.impactBuilderData);
}

abstract class ModularStrategy {
  // TODO(johnniwinther): Avoid the need for passing [pragmaAnnotations].
  ModularMemberData computeModularMemberData(
      ir.Member node, Set<PragmaAnnotation> pragmaAnnotations);
}
