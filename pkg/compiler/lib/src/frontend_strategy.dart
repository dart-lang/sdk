// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.frontend_strategy;

import 'common.dart';
import 'common_elements.dart';
import 'common/tasks.dart';
import 'elements/entities.dart';
import 'environment.dart';
import 'js_backend/native_data.dart';
import 'library_loader.dart';
import 'native/resolver.dart';
import 'serialization/task.dart';
import 'patch_parser.dart';
import 'resolved_uri_translator.dart';

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
}

/// Class that performs the mechanics to investigate annotations in the code.
abstract class AnnotationProcessor {
  void extractNativeAnnotations(
      LibraryEntity library, NativeBasicDataBuilder nativeBasicDataBuilder);

  void extractJsInteropAnnotations(
      LibraryEntity library, NativeBasicDataBuilder nativeBasicDataBuilder);
}
