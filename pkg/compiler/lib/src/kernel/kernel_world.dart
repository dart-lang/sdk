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
import '../universe/resolution_world_builder.dart';
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

  KClosedWorldImpl(this.elementMap,
      {CompilerOptions options,
      this.elementEnvironment,
      this.dartTypes,
      this.commonElements,
      this.nativeData,
      this.interceptorData,
      this.backendUsage,
      this.noSuchMethodData,
      ResolutionWorldBuilder resolutionWorldBuilder,
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
      this.annotationsData})
      : _implementedClasses = implementedClasses {
    _rtiNeed = rtiNeedBuilder.computeRuntimeTypesNeed(
        resolutionWorldBuilder, this, options);
  }

  @override
  RuntimeTypesNeed get rtiNeed => _rtiNeed;

  @override
  bool isImplemented(ClassEntity cls) {
    return _implementedClasses.contains(cls);
  }

  /// Needed for testing.
  Iterable<MemberEntity> get processedMembers => liveMemberUsage.keys;
}
