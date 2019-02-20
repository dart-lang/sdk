// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.frontend_strategy;

import 'common/backend_api.dart';
import 'common.dart';
import 'common_elements.dart';
import 'compiler.dart' show Compiler;
import 'deferred_load.dart' show DeferredLoadTask;
import 'elements/entities.dart';
import 'elements/types.dart';
import 'enqueue.dart';
import 'js_backend/annotations.dart';
import 'js_backend/field_analysis.dart' show KFieldAnalysis;
import 'js_backend/backend_usage.dart';
import 'js_backend/interceptor_data.dart';
import 'js_backend/native_data.dart';
import 'js_backend/no_such_method_registry.dart';
import 'js_backend/runtime_types.dart';
import 'kernel/loader.dart';
import 'native/enqueue.dart' show NativeResolutionEnqueuer;
import 'native/resolver.dart';
import 'universe/class_hierarchy.dart';
import 'universe/resolution_world_builder.dart';
import 'universe/world_builder.dart';
import 'universe/world_impact.dart';

/// Strategy pattern that defines the connection between the input format and
/// the resolved element model.
abstract class FrontendStrategy {
  /// Registers a set of loaded libraries with this strategy.
  void registerLoadedLibraries(KernelResult result);

  /// Returns the [ElementEnvironment] for the element model used in this
  /// strategy.
  ElementEnvironment get elementEnvironment;

  /// Returns the [CommonElements] for the element model used in this
  /// strategy.
  CommonElements get commonElements;

  /// Returns the [DartTypes] for the element model used in this strategy.
  DartTypes get dartTypes;

  /// Returns the [AnnotationProcessor] for this strategy.
  AnnotationProcessor get annotationProcesser;

  NativeBasicData get nativeBasicData;

  /// Creates a [DeferredLoadTask] for the element model used in this strategy.
  DeferredLoadTask createDeferredLoadTask(Compiler compiler);

  /// Creates the [NativeClassFinder] for this strategy.
  NativeClassFinder createNativeClassFinder(NativeBasicData nativeBasicData);

  /// Creates the [NoSuchMethodResolver] corresponding the resolved model of
  /// this strategy.
  NoSuchMethodResolver createNoSuchMethodResolver();

  /// Returns the [RuntimeTypesNeedBuilder] used by this frontend strategy.
  RuntimeTypesNeedBuilder get runtimeTypesNeedBuilderForTesting;

  /// Creates the [ResolutionWorldBuilder] corresponding to the element model
  /// used in this strategy.
  ResolutionWorldBuilder createResolutionWorldBuilder(
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      InterceptorDataBuilder interceptorDataBuilder,
      BackendUsageBuilder backendUsageBuilder,
      RuntimeTypesNeedBuilder rtiNeedBuilder,
      KFieldAnalysis allocatorAnalysis,
      NativeResolutionEnqueuer nativeResolutionEnqueuer,
      NoSuchMethodRegistry noSuchMethodRegistry,
      AnnotationsDataBuilder annotationsDataBuilder,
      SelectorConstraintsStrategy selectorConstraintsStrategy,
      ClassHierarchyBuilder classHierarchyBuilder,
      ClassQueries classQueries);

  /// Creates the [WorkItemBuilder] corresponding to how a resolved model for
  /// a single member is obtained in this strategy.
  WorkItemBuilder createResolutionWorkItemBuilder(
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      AnnotationsDataBuilder annotationsDataBuilder,
      ImpactTransformer impactTransformer,
      Map<Entity, WorldImpact> impactCache);

  /// Computes the main function from [mainLibrary] adding additional world
  /// impact to [impactBuilder].
  FunctionEntity computeMain(WorldImpactBuilder impactBuilder);

  /// Creates the [RuntimeTypesNeedBuilder] for this strategy.
  RuntimeTypesNeedBuilder createRuntimeTypesNeedBuilder();

  /// Creates the [ClassQueries] for this strategy.
  ClassQueries createClassQueries();

  /// Creates a [SourceSpan] from [spannable] in context of [currentElement].
  SourceSpan spanFromSpannable(Spannable spannable, Entity currentElement);
}

/// Class that performs the mechanics to investigate annotations in the code.
abstract class AnnotationProcessor {
  void extractNativeAnnotations(LibraryEntity library);

  void extractJsInteropAnnotations(LibraryEntity library);

  void processJsInteropAnnotations(
      NativeBasicData nativeBasicData, NativeDataBuilder nativeDataBuilder);
}

abstract class FrontendStrategyBase implements FrontendStrategy {
  final NativeBasicDataBuilderImpl nativeBasicDataBuilder =
      new NativeBasicDataBuilderImpl();
  NativeBasicData _nativeBasicData;

  NativeBasicData get nativeBasicData {
    if (_nativeBasicData == null) {
      _nativeBasicData = nativeBasicDataBuilder.close(elementEnvironment);
      assert(
          _nativeBasicData != null,
          failedAt(NO_LOCATION_SPANNABLE,
              "NativeBasicData has not been computed yet."));
    }
    return _nativeBasicData;
  }
}

/// Class that deletes the contents of an [WorldImpact] cache.
// TODO(redemption): this can be deleted when we sunset the old front end.
abstract class ImpactCacheDeleter {
  /// Removes the [WorldImpact] for [element] from the resolution cache. Later
  /// calls to [getWorldImpact] or [computeWorldImpact] returns an empty impact.
  void uncacheWorldImpact(Entity element);

  /// Removes the [WorldImpact]s for all [Element]s in the resolution cache. ,
  /// Later calls to [getWorldImpact] or [computeWorldImpact] returns an empty
  /// impact.
  void emptyCache();
}
