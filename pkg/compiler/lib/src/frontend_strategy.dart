// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.frontend_strategy;

import 'common.dart';
import 'common_elements.dart';
import 'common/backend_api.dart';
import 'common/tasks.dart';
import 'elements/entities.dart';
import 'elements/types.dart';
import 'environment.dart';
import 'enqueue.dart';
import 'js_backend/backend.dart';
import 'js_backend/backend_usage.dart';
import 'js_backend/interceptor_data.dart';
import 'js_backend/mirrors_analysis.dart';
import 'js_backend/mirrors_data.dart';
import 'js_backend/native_data.dart';
import 'js_backend/no_such_method_registry.dart';
import 'js_backend/runtime_types.dart';
import 'library_loader.dart';
import 'native/resolver.dart';
import 'serialization/task.dart';
import 'patch_parser.dart';
import 'resolved_uri_translator.dart';
import 'universe/world_builder.dart';
import 'universe/world_impact.dart';

/// Strategy pattern that defines the connection between the input format and
/// the resolved element model.
abstract class FrontendStrategy {
  /// Creates library loader task for this strategy.
  LibraryLoaderTask createLibraryLoader(
      ResolvedUriTranslator uriTranslator,
      ScriptLoader scriptLoader,
      ElementScanner scriptScanner,
      LibraryDeserializer deserializer,
      PatchResolverFunction patchResolverFunc,
      PatchParserTask patchParser,
      Environment environment,
      DiagnosticReporter reporter,
      Measurer measurer);

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

  /// Creates the [NativeClassFinder] for this strategy.
  NativeClassFinder createNativeClassFinder(NativeBasicData nativeBasicData);

  /// Creates the [NoSuchMethodResolver] corresponding the resolved model of
  /// this strategy.
  NoSuchMethodResolver createNoSuchMethodResolver();

  /// Creates the [ResolutionWorldBuilder] corresponding to the element model
  /// used in this strategy.
  ResolutionWorldBuilder createResolutionWorldBuilder(
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      InterceptorDataBuilder interceptorDataBuilder,
      BackendUsageBuilder backendUsageBuilder,
      SelectorConstraintsStrategy selectorConstraintsStrategy);

  /// Creates the [WorkItemBuilder] corresponding to how a resolved model for
  /// a single member is obtained in this strategy.
  WorkItemBuilder createResolutionWorkItemBuilder(
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      ImpactTransformer impactTransformer);

  /// Computes the main function from [mainLibrary] adding additional world
  /// impact to [impactBuilder].
  FunctionEntity computeMain(
      LibraryEntity mainLibrary, WorldImpactBuilder impactBuilder);

  // TODO(johnniwinther): Reuse the following classes between strategies:

  /// Creates the [MirrorsDataBuilder] for this strategy.
  MirrorsDataBuilder createMirrorsDataBuilder();

  /// Creates the [MirrorsResolutionAnalysis] for this strategy.
  // TODO(johnniwinther): Avoid passing [JavaScriptBackend].
  MirrorsResolutionAnalysis createMirrorsResolutionAnalysis(
      JavaScriptBackend backend);

  /// Creates the [RuntimeTypesNeedBuilder] for this strategy.
  RuntimeTypesNeedBuilder createRuntimeTypesNeedBuilder();

  /// Creates a [SourceSpan] from [spannable] in context of [currentElement].
  SourceSpan spanFromSpannable(Spannable spannable, Entity currentElement);
}

/// Class that performs the mechanics to investigate annotations in the code.
abstract class AnnotationProcessor {
  void extractNativeAnnotations(
      LibraryEntity library, NativeBasicDataBuilder nativeBasicDataBuilder);

  void extractJsInteropAnnotations(
      LibraryEntity library, NativeBasicDataBuilder nativeBasicDataBuilder);

  void processJsInteropAnnotations(
      NativeBasicData nativeBasicData, NativeDataBuilder nativeDataBuilder);
}
