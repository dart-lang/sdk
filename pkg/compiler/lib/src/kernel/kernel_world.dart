// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart';

import '../elements/entities.dart';

import '../elements/types.dart';
import '../js_backend/annotations.dart';
import '../js_backend/field_analysis.dart' show KFieldAnalysis;
import '../js_backend/backend_usage.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types.dart';
import '../options.dart';
import '../universe/class_hierarchy.dart';
import '../universe/member_usage.dart';
import '../universe/selector.dart';
import '../world.dart';

import 'element_map_impl.dart';

class KClosedWorldImpl implements KClosedWorld {
  final KernelToElementMapImpl elementMap;

  @override
  final KElementEnvironment elementEnvironment;

  @override
  final DartTypes dartTypes;

  @override
  final KCommonElements commonElements;

  @override
  final NativeData nativeData;

  @override
  final InterceptorData interceptorData;

  @override
  final BackendUsage backendUsage;

  @override
  final NoSuchMethodData noSuchMethodData;

  @override
  final Map<ClassEntity, Set<ClassEntity>> mixinUses;

  @override
  final Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses;

  // TODO(johnniwinther): Can this be derived from [ClassSet]s?
  final Set<ClassEntity> _implementedClasses;

  @override
  final Iterable<MemberEntity> liveInstanceMembers;

  @override
  final Iterable<MemberEntity> assignedInstanceMembers;
  @override
  final KFieldAnalysis fieldAnalysis;

  @override
  final Iterable<ClassEntity> liveNativeClasses;

  @override
  final Map<MemberEntity, MemberUsage> liveMemberUsage;

  @override
  final ClassHierarchy classHierarchy;

  @override
  final AnnotationsData annotationsData;

  RuntimeTypesNeed _rtiNeed;

  @override
  final Set<DartType> isChecks;

  final Map<Entity, Set<DartType>> staticTypeArgumentDependencies;

  final Map<Selector, Set<DartType>> dynamicTypeArgumentDependencies;

  /// Set of methods in instantiated classes that are potentially closurized.
  @override
  final Set<FunctionEntity> closurizedMembers;

  /// Set of static or top level methods that are closurized.
  @override
  final Set<FunctionEntity> closurizedStatics;

  @override
  final Set<TypeVariableType> typeVariableTypeLiterals;

  @override
  final Set<Local> genericLocalFunctions;

  @override
  final Iterable<FunctionEntity> genericInstanceMethods;

  @override
  final Iterable<FunctionEntity> genericMethods;

  @override
  final Set<FunctionEntity> closurizedMembersWithFreeTypeVariables;

  @override
  final Iterable<Local> localFunctions;

  @override
  final Iterable<InterfaceType> instantiatedTypes;

  @override
  final Iterable<FunctionEntity> userNoSuchMethods;

  @override
  RuntimeTypesNeed get rtiNeed => _rtiNeed;

  KClosedWorldImpl(this.elementMap,
      {CompilerOptions options,
      this.elementEnvironment,
      this.dartTypes,
      this.commonElements,
      this.nativeData,
      this.interceptorData,
      this.backendUsage,
      this.noSuchMethodData,
      RuntimeTypesNeedBuilder rtiNeedBuilder,
      this.fieldAnalysis,
      Set<ClassEntity> implementedClasses,
      this.liveNativeClasses,
      this.liveInstanceMembers,
      this.assignedInstanceMembers,
      this.liveMemberUsage,
      this.mixinUses,
      this.typesImplementedBySubclasses,
      this.classHierarchy,
      this.annotationsData,
      this.isChecks,
      this.staticTypeArgumentDependencies,
      this.dynamicTypeArgumentDependencies,
      this.closurizedMembers,
      this.closurizedStatics,
      this.typeVariableTypeLiterals,
      this.genericLocalFunctions,
      this.genericInstanceMethods,
      this.genericMethods,
      this.closurizedMembersWithFreeTypeVariables,
      this.localFunctions,
      this.instantiatedTypes,
      this.userNoSuchMethods})
      : _implementedClasses = implementedClasses {
    _rtiNeed = rtiNeedBuilder.computeRuntimeTypesNeed(this, options);
  }

  @override
  bool isImplemented(ClassEntity cls) {
    return _implementedClasses.contains(cls);
  }

  /// Needed for testing.
  Iterable<MemberEntity> get processedMembers => liveMemberUsage.keys;

  @override
  void forEachStaticTypeArgument(
      void f(Entity function, Set<DartType> typeArguments)) {
    staticTypeArgumentDependencies.forEach(f);
  }

  @override
  void forEachDynamicTypeArgument(
      void f(Selector selector, Set<DartType> typeArguments)) {
    dynamicTypeArgumentDependencies.forEach(f);
  }

  @override
  bool isMemberUsed(MemberEntity member) => liveMemberUsage.containsKey(member);
}
