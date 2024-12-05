// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:wasm_builder/wasm_builder.dart' as w;

import 'translator.dart';

class ExceptionTag {
  final Translator translator;

  late final w.Tag _definedTag = _defineExceptionTag();
  final WasmTagImporter _importedTags;

  ExceptionTag(this.translator)
      : _importedTags = WasmTagImporter(translator, 'exception');

  /// Get the exception tag reference for [module].
  w.Tag getExceptionTag(w.ModuleBuilder module) {
    return _importedTags.get(_definedTag, module);
  }

  /// Creates a [w.Tag] for a void [w.FunctionType] with two parameters,
  /// a [topInfo.nonNullableType] parameter to hold an exception, and a
  /// [stackTraceInfo.nonNullableType] to hold a stack trace. This single
  /// exception tag is used to throw and catch all Dart exceptions.
  w.Tag _defineExceptionTag() {
    final w.FunctionType tagType = translator.typesBuilder.defineFunction([
      translator.topInfo.nonNullableType,
      translator.stackTraceInfo.repr.nonNullableType
    ], const []);
    return translator.mainModule.tags.define(tagType);
  }
}
