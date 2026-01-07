// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:wasm_builder/wasm_builder.dart' as w;

import 'translator.dart';

class ExceptionTags {
  final Translator translator;

  late final w.Tag _definedDartTag = _defineDartExceptionTag();

  late final w.Tag _importedJsTag = _importJsExceptionTag();

  final WasmTagImporter _importedTags;

  ExceptionTags(this.translator)
      : _importedTags = WasmTagImporter(translator, 'exception');

  /// Get the Dart exception tag for [module].
  ///
  /// This tag catches Dart exceptions.
  w.Tag getDartExceptionTag(w.ModuleBuilder module) =>
      _importedTags.get(_definedDartTag, module);

  /// Get the JS exception tag for [module].
  ///
  /// This tag catches JS exceptions.
  w.Tag getJsExceptionTag(w.ModuleBuilder module) =>
      _importedTags.get(_importedJsTag, module);

  /// Creates a [w.Tag] for a void [w.FunctionType] with two parameters,
  /// a [topInfo.nonNullableType] parameter to hold an exception, and a
  /// [stackTraceInfo.nonNullableType] to hold a stack trace. This single
  /// exception tag is used to throw and catch all Dart exceptions.
  w.Tag _defineDartExceptionTag() {
    final w.FunctionType tagType = translator.typesBuilder.defineFunction(
        [translator.topTypeNonNullable, translator.stackTraceType], const []);
    return translator.mainModule.tags.define(tagType);
  }

  w.Tag _importJsExceptionTag() {
    final w.FunctionType tagType = translator.typesBuilder
        .defineFunction(const [w.RefType.extern(nullable: true)], const []);
    return translator.mainModule.tags.import('WebAssembly', 'JSTag', tagType);
  }
}
