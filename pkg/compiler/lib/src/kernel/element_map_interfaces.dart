// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Facade interfaces for KernelToElementMap.
// TODO(48820): Remove after migrating element_map.dart and
// element_map_impl.dart.

import 'package:kernel/ast.dart' as ir
    show Class, DartType, Field, Member, Procedure, ProcedureStubKind;

import '../common.dart' show DiagnosticReporter;
import '../common/elements.dart' show CommonElements, ElementEnvironment;
import '../elements/entities.dart'
    show ClassEntity, ConstructorEntity, MemberEntity;
import '../elements/indexed.dart' show IndexedClass;
import '../elements/types.dart' show DartType, DartTypes, InterfaceType;
import '../ir/constants.dart' show Dart2jsConstantEvaluator;
import '../native/behavior.dart';
import '../options.dart';

abstract class KernelElementEnvironment implements ElementEnvironment {}

abstract class KernelToElementMapForNativeData {
  KernelElementEnvironment get elementEnvironment;

  ClassEntity getClass(ir.Class node);
  MemberEntity getMember(ir.Member node);
  NativeBehavior getNativeBehaviorForMethod(ir.Member member,
      Iterable<String> createsAnnotations, Iterable<String> returnsAnnotations,
      {required bool isJsInterop});
  NativeBehavior getNativeBehaviorForFieldLoad(ir.Field field,
      Iterable<String> createsAnnotations, Iterable<String> returnsAnnotations,
      {required bool isJsInterop});
  NativeBehavior getNativeBehaviorForFieldStore(ir.Field field);
}

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

// Members which dart2js ignores.
bool memberIsIgnorable(ir.Member node, {ir.Class? cls}) {
  if (node is! ir.Procedure) return false;
  ir.Procedure member = node;
  switch (member.stubKind) {
    case ir.ProcedureStubKind.Regular:
    case ir.ProcedureStubKind.ConcreteForwardingStub:
    case ir.ProcedureStubKind.NoSuchMethodForwarder:
      return false;
    case ir.ProcedureStubKind.AbstractForwardingStub:
    case ir.ProcedureStubKind.MemberSignature:
    case ir.ProcedureStubKind.AbstractMixinStub:
    case ir.ProcedureStubKind.ConcreteMixinStub:
      return true;
  }
}
