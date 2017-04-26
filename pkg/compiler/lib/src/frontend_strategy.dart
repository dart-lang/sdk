// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.frontend_strategy;

import 'common.dart';
import 'common_elements.dart';
import 'common/backend_api.dart';
import 'common/tasks.dart';
import 'elements/entities.dart';
import 'environment.dart';
import 'enqueue.dart';
import 'js_backend/backend.dart';
import 'js_backend/backend_usage.dart';
import 'js_backend/custom_elements_analysis.dart';
import 'js_backend/mirrors_analysis.dart';
import 'js_backend/mirrors_data.dart';
import 'js_backend/native_data.dart';
import 'js_backend/no_such_method_registry.dart';
import 'library_loader.dart';
import 'native/resolver.dart';
import 'serialization/task.dart';
import 'patch_parser.dart';
import 'resolved_uri_translator.dart';
import 'universe/world_builder.dart';

/// Strategy pattern that defines the connection between the input format and
/// the resolved element model.
abstract class FrontEndStrategy {
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

  /// Returns the [AnnotationProcessor] for this strategy.
  AnnotationProcessor get annotationProcesser;

  /// Creates the [NativeClassFinder] for this strategy.
  NativeClassFinder createNativeClassResolver(NativeBasicData nativeBasicData);

  /// Creates the [NoSuchMethodResolver] corresponding the resolved model of
  /// this strategy.
  NoSuchMethodResolver createNoSuchMethodResolver();

  /// Creates the [ResolutionWorldBuilder] corresponding to the element model
  /// used in this strategy.
  ResolutionWorldBuilder createResolutionWorldBuilder(
      NativeBasicData nativeBasicData,
      SelectorConstraintsStrategy selectorConstraintsStrategy);

  /// Creates the [WorkItemBuilder] corresponding to how a resolved model for
  /// a single member is obtained in this strategy.
  WorkItemBuilder createResolutionWorkItemBuilder(
      ImpactTransformer impactTransformer);

  // TODO(johnniwinther): Reuse the following classes between strategies:

  /// Creates the [CustomElementsResolutionAnalysis] for this strategy.
  CustomElementsResolutionAnalysis createCustomElementsResolutionAnalysis(
      NativeBasicData nativeBasicData, BackendUsageBuilder backendUsageBuilder);

  /// Creates the [MirrorsDataBuilder] for this strategy.
  MirrorsDataBuilder createMirrorsDataBuilder();

  /// Creates the [MirrorsResolutionAnalysis] for this strategy.
  // TODO(johnniwinther): Avoid passing [JavaScriptBackend].
  MirrorsResolutionAnalysis createMirrorsResolutionAnalysis(
      JavaScriptBackend backend);

  /// Creates the [RuntimeTypesNeedBuilder] for this strategy.
  RuntimeTypesNeedBuilder createRuntimeTypesNeedBuilder();
}

/// Class that performs the mechanics to investigate annotations in the code.
abstract class AnnotationProcessor {
  void extractNativeAnnotations(
      LibraryEntity library, NativeBasicDataBuilder nativeBasicDataBuilder);

  void extractJsInteropAnnotations(
      LibraryEntity library, NativeBasicDataBuilder nativeBasicDataBuilder);
}
