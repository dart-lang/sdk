// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Facade interfaces for KernelToElementMap.
// TODO(48820): Remove after migrating element_map.dart and
// element_map_impl.dart.

import 'package:kernel/ast.dart' as ir show DartType, Member;

import '../common.dart' show DiagnosticReporter;
import '../common/elements.dart' show CommonElements;
import '../elements/entities.dart' show ClassEntity, ConstructorEntity;
import '../elements/indexed.dart' show IndexedClass;
import '../elements/types.dart' show DartType, DartTypes, InterfaceType;
import '../ir/constants.dart' show Dart2jsConstantEvaluator;
import '../options.dart';

abstract class KernelToElementMapForClassHierarchy {
  ClassEntity? getSuperClass(ClassEntity cls);
  int getHierarchyDepth(IndexedClass cls);
  Iterable<InterfaceType> getSuperTypes(ClassEntity cls);
  ClassEntity? getAppliedMixin(IndexedClass cls);
  bool implementsFunction(IndexedClass cls);
}

abstract class KernelToElementMapForImpactData {
  CommonElements get commonElements;
  Dart2jsConstantEvaluator get constantEvaluator;
  CompilerOptions get options;
  DiagnosticReporter get reporter;
  DartTypes get types;

  ConstructorEntity getConstructor(ir.Member node);
  DartType getDartType(ir.DartType type);
}
