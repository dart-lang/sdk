// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common/elements.dart';
import '../common/names.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_backend/annotations.dart';
import '../js_backend/field_analysis.dart' show KFieldAnalysis;
import '../js_backend/backend_usage.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types_resolution.dart';
import '../js_model/elements.dart';
import '../options.dart';
import '../universe/class_hierarchy.dart';
import '../universe/member_usage.dart';
import '../universe/selector.dart';
import '../world.dart';

import 'element_map.dart';

/// The immutable result of the [ResolutionWorldBuilder].
class KClosedWorld implements BuiltWorld {
  final KernelToElementMap elementMap;
  final KElementEnvironment elementEnvironment;
  final DartTypes dartTypes;
  final KCommonElements commonElements;

  final NativeData nativeData;
  final InterceptorData interceptorData;
  final BackendUsage backendUsage;
  final NoSuchMethodData noSuchMethodData;
  final Map<ClassEntity, Set<ClassEntity>> mixinUses;
  final Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses;

  // TODO(johnniwinther): Can this be derived from [ClassSet]s?
  final Set<ClassEntity> _implementedClasses;
  final Iterable<MemberEntity> liveInstanceMembers;
  final Iterable<MemberEntity> liveAbstractInstanceMembers;

  /// Members that are written either directly or through a setter selector.
  final Iterable<MemberEntity> assignedInstanceMembers;

  final KFieldAnalysis fieldAnalysis;
  final Iterable<ClassEntity> liveNativeClasses;
  final Map<MemberEntity, MemberUsage> liveMemberUsage;

  @override
  final ClassHierarchy classHierarchy;

  @override
  final AnnotationsData annotationsData;

  late RuntimeTypesNeed _rtiNeed;

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

  /// Set of live closurized members whose signatures reference type variables.
  ///
  /// A closurized method is considered live if the enclosing class has been
  /// instantiated.
  final Set<FunctionEntity> closurizedMembersWithFreeTypeVariables;

  /// Set of (live) local functions (closures).
  ///
  /// A live function is one whose enclosing member function has been enqueued.
  final Iterable<Local> localFunctions;

  @override
  final Iterable<InterfaceType> instantiatedTypes;

  final Iterable<RecordType> instantiatedRecordTypes;

  RuntimeTypesNeed get rtiNeed => _rtiNeed;

  KClosedWorld(this.elementMap,
      {required CompilerOptions options,
      required this.elementEnvironment,
      required this.dartTypes,
      required this.commonElements,
      required this.nativeData,
      required this.interceptorData,
      required this.backendUsage,
      required this.noSuchMethodData,
      required RuntimeTypesNeedBuilder rtiNeedBuilder,
      required this.fieldAnalysis,
      required Set<ClassEntity> implementedClasses,
      required this.liveNativeClasses,
      required this.liveInstanceMembers,
      required this.liveAbstractInstanceMembers,
      required this.assignedInstanceMembers,
      required this.liveMemberUsage,
      required this.mixinUses,
      required this.typesImplementedBySubclasses,
      required this.classHierarchy,
      required this.annotationsData,
      required this.isChecks,
      required this.namedTypeVariablesNewRti,
      required this.staticTypeArgumentDependencies,
      required this.dynamicTypeArgumentDependencies,
      required this.typeVariableTypeLiterals,
      required this.genericLocalFunctions,
      required this.closurizedMembersWithFreeTypeVariables,
      required this.localFunctions,
      required this.instantiatedTypes,
      required this.instantiatedRecordTypes})
      : _implementedClasses = implementedClasses {
    _rtiNeed = rtiNeedBuilder.computeRuntimeTypesNeed(this, options);
    assert(_checkIntegrity());
  }

  bool _checkIntegrity() {
    for (MemberEntity member in liveMemberUsage.keys) {
      if (member.enclosingClass != null) {
        if (!elementMap.classes
            .getEnv(member.enclosingClass as JClass)
            .checkHasMember(elementMap.getMemberNode(member))) {
          throw SpannableAssertionFailure(
              member,
              "Member $member is not in the environment of its enclosing class"
              " ${member.enclosingClass}.");
        }
      }
    }
    return true;
  }

  /// Returns `true` if [cls] is implemented by an instantiated class.
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

  /// Returns `true` if [member] has been marked as used (called, read, etc.) in
  /// this world builder.
  bool isMemberUsed(MemberEntity member) => liveMemberUsage.containsKey(member);

  @override
  void forEachGenericMethod(void Function(FunctionEntity e) f) {
    liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
      if (member is FunctionEntity &&
          elementEnvironment.getFunctionTypeVariables(member).isNotEmpty) {
        f(member);
      }
    });
  }

  @override
  void forEachGenericInstanceMethod(void Function(FunctionEntity e) f) {
    liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
      if (member is FunctionEntity &&
          member.isInstanceMember &&
          elementEnvironment.getFunctionTypeVariables(member).isNotEmpty) {
        f(member);
      }
    });
  }

  @override
  late final Iterable<FunctionEntity> userNoSuchMethods = (() {
    final result = <FunctionEntity>[];
    liveMemberUsage.forEach((MemberEntity member, MemberUsage memberUsage) {
      if (member is FunctionEntity && memberUsage.hasUse) {
        if (member.isInstanceMember &&
            member.name == Identifiers.noSuchMethod_ &&
            !commonElements.isDefaultNoSuchMethodImplementation(member)) {
          result.add(member);
        }
      }
    });
    return result;
  })();

  @override
  late final Iterable<FunctionEntity> closurizedMembers = (() {
    final result = <FunctionEntity>{};
    liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
      if (member.isFunction && member.isInstanceMember && usage.hasRead) {
        result.add(member as FunctionEntity);
      }
    });
    return result;
  }());

  @override
  late final Iterable<FunctionEntity> closurizedStatics = (() {
    final result = <FunctionEntity>{};
    liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
      if (member.isFunction &&
          (member.isStatic || member.isTopLevel) &&
          usage.hasRead) {
        result.add(member as FunctionEntity);
      }
    });
    return result;
  })();

  @override
  late final Map<MemberEntity, DartType> genericCallableProperties = (() {
    final result = <MemberEntity, DartType>{};
    liveMemberUsage.forEach((MemberEntity member, MemberUsage usage) {
      if (usage.hasRead) {
        DartType? type;
        if (member is FieldEntity) {
          type = elementEnvironment.getFieldType(member);
        } else if (member.isGetter) {
          type = elementEnvironment
              .getFunctionType(member as FunctionEntity)
              .returnType;
        }
        if (type == null) return;
        if (dartTypes.canAssignGenericFunctionTo(type)) {
          result[member] = type;
        } else {
          type = type.withoutNullability;
          if (type is InterfaceType) {
            FunctionType? callType = dartTypes.getCallType(type);
            if (callType != null &&
                dartTypes.canAssignGenericFunctionTo(callType)) {
              result[member] = callType;
            }
          }
        }
      }
    });
    return result;
  })();
}
