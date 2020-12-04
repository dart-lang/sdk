// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../js_backend/annotations.dart';
import '../util/enumset.dart';
import 'annotations.dart';
import 'constants.dart';
import 'impact.dart';
import 'scope.dart';

class ModularCore {
  final ir.Component component;
  final Dart2jsConstantEvaluator constantEvaluator;

  ModularCore(this.component, this.constantEvaluator);
}

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
