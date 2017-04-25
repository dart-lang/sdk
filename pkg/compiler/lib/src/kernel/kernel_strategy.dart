// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.frontend_strategy;

import '../common.dart';
import '../common_elements.dart';
import '../common/tasks.dart';
import '../environment.dart' as env;
import '../frontend_strategy.dart';
import '../library_loader.dart';
import '../serialization/task.dart';
import '../patch_parser.dart';
import '../resolved_uri_translator.dart';
import 'element_map.dart';

/// Front end strategy that loads '.dill' files and builds a resolved element
/// model from kernel IR nodes.
class KernelFrontEndStrategy implements FrontEndStrategy {
  KernelToElementMap elementMap;

  KernelAnnotationProcessor _annotationProcesser;

  KernelFrontEndStrategy(DiagnosticReporter reporter)
      : elementMap = new KernelToElementMap(reporter);

  @override
  LibraryLoaderTask createLibraryLoader(
      ResolvedUriTranslator uriTranslator,
      ScriptLoader scriptLoader,
      ElementScanner scriptScanner,
      LibraryDeserializer deserializer,
      PatchResolverFunction patchResolverFunc,
      PatchParserTask patchParser,
      env.Environment environment,
      DiagnosticReporter reporter,
      Measurer measurer) {
    return new DillLibraryLoaderTask(
        elementMap, uriTranslator, scriptLoader, reporter, measurer);
  }

  @override
  ElementEnvironment get elementEnvironment => elementMap.elementEnvironment;

  @override
  AnnotationProcessor get annotationProcesser =>
      _annotationProcesser ??= new KernelAnnotationProcessor(elementMap);
}
