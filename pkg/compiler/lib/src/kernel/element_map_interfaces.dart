// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Facade interfaces for KernelToElementMap.
// TODO(48820): Remove after migrating element_map.dart and
// element_map_impl.dart.

import 'package:kernel/ast.dart' as ir
    show
        Class,
        Constructor,
        DartType,
        Expression,
        Field,
        InterfaceType,
        LibraryDependency,
        LocalFunction,
        Member,
        Name,
        Procedure,
        ProcedureStubKind,
        StaticInvocation;
import 'package:kernel/type_environment.dart' as ir
    show TypeEnvironment, StaticTypeContext;
import '../common.dart' show DiagnosticReporter;
import '../common/elements.dart' show CommonElements, ElementEnvironment;
import '../elements/entities.dart'
    show
        ClassEntity,
        ConstructorEntity,
        FieldEntity,
        FunctionEntity,
        Local,
        MemberEntity,
        ImportEntity;
import '../constants/values.dart';
import '../elements/indexed.dart'
    show
        EntityDataEnvMap,
        EntityDataMap,
        IndexedClass,
        IndexedMember,
        IndexedLibrary,
        IndexedTypeVariable;
import '../elements/names.dart' show Name;
import '../elements/types.dart' show DartType, DartTypes, InterfaceType;
import '../ir/constants.dart' show Dart2jsConstantEvaluator;
import '../ir/element_map.dart' show IrToElementMap;
import '../native/behavior.dart';
import '../js_backend/native_data.dart' show NativeBasicData;
import '../options.dart';
import '../universe/selector.dart';
import 'env_interfaces.dart';

enum ForeignKind {
  JS,
  JS_BUILTIN,
  JS_EMBEDDED_GLOBAL,
  JS_INTERCEPTOR_CONSTANT,
  NONE,
}

abstract class KernelElementEnvironment implements ElementEnvironment {
  Iterable<ConstantValue> getMemberMetadata(MemberEntity member,
      {bool includeParameterMetadata = false});
}

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

abstract class KernelToElementMapForDeferredLoading {
  CommonElements get commonElements;
  ConstantValue? getConstantValue(
      ir.StaticTypeContext staticTypeContext, ir.Expression node,
      {bool requireConstant = true,
      bool implicitNull = false,
      bool checkCasts = true});
  ImportEntity getImport(ir.LibraryDependency? node);
  ir.Member getMemberNode(MemberEntity member);
  ir.StaticTypeContext getStaticTypeContext(MemberEntity member);
}

abstract class KernelToElementMapForKernelImpact {
  CommonElements get commonElements;
  KernelElementEnvironment get elementEnvironment;
  NativeBasicData get nativeBasicData;
  ir.TypeEnvironment get typeEnvironment;
  InterfaceType createInterfaceType(
      ir.Class cls, List<ir.DartType> typeArguments);
  ClassEntity getClass(ir.Class node);
  ConstantValue? getConstantValue(
      ir.StaticTypeContext staticTypeContext, ir.Expression node,
      {bool requireConstant = true,
      bool implicitNull = false,
      bool checkCasts = true});
  ConstructorEntity getConstructor(ir.Member node);
  ConstructorEntity getSuperConstructor(
      ir.Constructor sourceNode, ir.Member targetNode);
  DartType getDartType(ir.DartType type);
  FieldEntity getField(ir.Field node);
  ForeignKind getForeignKind(ir.StaticInvocation node);
  FunctionEntity getMethod(ir.Procedure node);
  FunctionEntity getSuperNoSuchMethod(ClassEntity cls);
  InterfaceType getInterfaceType(ir.InterfaceType type);
  ImportEntity? getImport(ir.LibraryDependency? node);
  InterfaceType? getInterfaceTypeForJsInterceptorCall(ir.StaticInvocation node);
  Local getLocalFunction(ir.LocalFunction node);
  MemberEntity getMember(ir.Member node);
  Name getName(ir.Name name);
  NativeBehavior getNativeBehaviorForFieldLoad(ir.Field field,
      Iterable<String> createsAnnotations, Iterable<String> returnsAnnotations,
      {required bool isJsInterop});
  NativeBehavior getNativeBehaviorForFieldStore(ir.Field field);
  NativeBehavior getNativeBehaviorForJsBuiltinCall(ir.StaticInvocation node);
  NativeBehavior getNativeBehaviorForJsCall(ir.StaticInvocation node);
  NativeBehavior getNativeBehaviorForJsEmbeddedGlobalCall(
      ir.StaticInvocation node);
  NativeBehavior getNativeBehaviorForMethod(ir.Member member,
      Iterable<String> createsAnnotations, Iterable<String> returnsAnnotations,
      {required bool isJsInterop});
  Selector getInvocationSelector(ir.Name irName, int positionalArguments,
      List<String> namedArguments, int typeArguments);
}

abstract class KernelToElementMapForJsModel implements IrToElementMap {
  CompilerOptions get options;
  EntityDataEnvMap<IndexedLibrary, KLibraryData, KLibraryEnv> get libraries;

  EntityDataEnvMap<IndexedClass, KClassData, KClassEnv> get classes;
  EntityDataMap<IndexedMember, KMemberData> get members;
  EntityDataMap<IndexedTypeVariable, KTypeVariableData> get typeVariables;

  KProgramEnv get env;
  bool get envIsClosed;
  set envIsClosed(bool v);
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
