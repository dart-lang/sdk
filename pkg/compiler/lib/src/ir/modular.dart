// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../ir/impact_data.dart';
import '../js_backend/annotations.dart';
import '../kernel/element_map.dart';
import '../util/enumset.dart';
import 'annotations.dart';
import 'impact.dart';
import 'scope.dart';

class ModularMemberData {
  final ScopeModel scopeModel;
  final ImpactBuilderData impactBuilderData;

  ModularMemberData(this.scopeModel, this.impactBuilderData);
}

abstract class ModularStrategy {
  List<PragmaAnnotationData> getPragmaAnnotationData(ir.Member node);

  // TODO(johnniwinther): Avoid the need for passing [pragmaAnnotations].
  ModularMemberData getModularMemberData(
      ir.Member node, EnumSet<PragmaAnnotation> pragmaAnnotations);
}

/// Compute [ModularMemberData] from the IR.
ModularMemberData computeModularMemberData(
    KernelToElementMap elementMap,
    ir.Member node,
    ScopeModel scopeModel,
    EnumSet<PragmaAnnotation> annotations) {
  return ModularMemberData(
      scopeModel, ImpactBuilder(elementMap, node).computeImpact());
}

class ModularCore {
  final ir.Component component;
  final ir.TypeEnvironment typeEnvironment;

  ModularCore(this.component, this.typeEnvironment);
}
