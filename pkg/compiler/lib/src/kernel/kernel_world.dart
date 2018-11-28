// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart';

import '../elements/entities.dart';

import '../elements/types.dart';
import '../js_backend/annotations.dart';
import '../js_backend/allocator_analysis.dart' show KAllocatorAnalysis;
import '../js_backend/backend_usage.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types.dart';
import '../options.dart';
import '../universe/class_hierarchy.dart';
import '../universe/resolution_world_builder.dart';
import '../world.dart';

import 'element_map_impl.dart';

class KClosedWorldImpl implements KClosedWorld {
  final KernelToElementMapImpl elementMap;
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

  /// Members that are written either directly or through a setter selector.
  final Iterable<MemberEntity> assignedInstanceMembers;
  final KAllocatorAnalysis allocatorAnalysis;

  final Iterable<ClassEntity> liveNativeClasses;

  final Iterable<MemberEntity> processedMembers;

  final ClassHierarchy classHierarchy;

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
      this.allocatorAnalysis,
      Set<ClassEntity> implementedClasses,
      this.liveNativeClasses,
      this.liveInstanceMembers,
      this.assignedInstanceMembers,
      this.processedMembers,
      this.mixinUses,
      this.typesImplementedBySubclasses,
      this.classHierarchy,
      this.annotationsData})
      : _implementedClasses = implementedClasses {
    _rtiNeed = rtiNeedBuilder.computeRuntimeTypesNeed(
        resolutionWorldBuilder, this, options);
  }

  RuntimeTypesNeed get rtiNeed => _rtiNeed;

  /// Returns `true` if [cls] is implemented by an instantiated class.
  bool isImplemented(ClassEntity cls) {
    return _implementedClasses.contains(cls);
  }
}
