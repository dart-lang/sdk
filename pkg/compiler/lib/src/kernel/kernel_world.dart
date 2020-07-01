// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/names.dart';
import '../common_elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_backend/annotations.dart';
import '../js_backend/field_analysis.dart' show KFieldAnalysis;
import '../js_backend/backend_usage.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types_resolution.dart';
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

  @override
  final Set<TypeVariableType> namedTypeVariablesNewRti;

  final Map<Entity, Set<DartType>> staticTypeArgumentDependencies;

  final Map<Selector, Set<DartType>> dynamicTypeArgumentDependencies;

  @override
  final Set<TypeVariableType> typeVariableTypeLiterals;

  @override
  final Set<Local> genericLocalFunctions;

  @override
  final Set<FunctionEntity> closurizedMembersWithFreeTypeVariables;

  @override
  final Iterable<Local> localFunctions;

  @override
  final Iterable<InterfaceType> instantiatedTypes;

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
      this.namedTypeVariablesNewRti,
      this.staticTypeArgumentDependencies,
      this.dynamicTypeArgumentDependencies,
      this.typeVariableTypeLiterals,
      this.genericLocalFunctions,
      this.closurizedMembersWithFreeTypeVariables,
      this.localFunctions,
      this.instantiatedTypes})
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

  @override
  void forEachGenericMethod(Function f) {
    liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
      if (member is FunctionEntity &&
          elementEnvironment.getFunctionTypeVariables(member).isNotEmpty) {
        f(member);
      }
    });
  }

  @override
  void forEachGenericInstanceMethod(Function f) {
    liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
      if (member is FunctionEntity &&
          member.isInstanceMember &&
          elementEnvironment.getFunctionTypeVariables(member).isNotEmpty) {
        f(member);
      }
    });
  }

  List<FunctionEntity> _userNoSuchMethodsCache;

  @override
  Iterable<FunctionEntity> get userNoSuchMethods {
    if (_userNoSuchMethodsCache == null) {
      _userNoSuchMethodsCache = <FunctionEntity>[];

      liveMemberUsage.forEach((MemberEntity member, MemberUsage memberUsage) {
        if (member is FunctionEntity && memberUsage.hasUse) {
          if (member.isInstanceMember &&
              member.name == Identifiers.noSuchMethod_ &&
              !commonElements.isDefaultNoSuchMethodImplementation(member)) {
            _userNoSuchMethodsCache.add(member);
          }
        }
      });
    }

    return _userNoSuchMethodsCache;
  }

  Set<FunctionEntity> _closurizedMembersCache;

  @override
  Iterable<FunctionEntity> get closurizedMembers {
    if (_closurizedMembersCache == null) {
      _closurizedMembersCache = {};
      liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
        if (member.isFunction && member.isInstanceMember && usage.hasRead) {
          _closurizedMembersCache.add(member);
        }
      });
    }
    return _closurizedMembersCache;
  }

  Set<FunctionEntity> _closurizedStaticsCache;

  @override
  Iterable<FunctionEntity> get closurizedStatics {
    if (_closurizedStaticsCache == null) {
      _closurizedStaticsCache = {};
      liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
        if (member.isFunction &&
            (member.isStatic || member.isTopLevel) &&
            usage.hasRead) {
          _closurizedStaticsCache.add(member);
        }
      });
    }
    return _closurizedStaticsCache;
  }

  Map<MemberEntity, DartType> _genericCallablePropertiesCache;

  @override
  Map<MemberEntity, DartType> get genericCallableProperties {
    if (_genericCallablePropertiesCache == null) {
      _genericCallablePropertiesCache = {};
      liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
        if (usage.hasRead) {
          DartType type;
          if (member.isField) {
            type = elementEnvironment.getFieldType(member);
          } else if (member.isGetter) {
            type = elementEnvironment.getFunctionType(member).returnType;
          }
          if (type == null) return;
          if (dartTypes.canAssignGenericFunctionTo(type)) {
            _genericCallablePropertiesCache[member] = type;
          }
        }
      });
    }
    return _genericCallablePropertiesCache;
  }
}
