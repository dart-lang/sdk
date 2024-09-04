// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:wasm_builder/wasm_builder.dart' as w;

import 'translator.dart';

class ExceptionTag {
  static const String _exceptionTagName = 'exception';
  final Translator translator;

  ExceptionTag(this.translator);

  final Map<w.ModuleBuilder, w.Tag> _exceptionTag = {};

  /// Get the exception tag reference for [module].
  w.Tag getExceptionTag(w.ModuleBuilder module) {
    return translator.isMainModule(module)
        ? _defineExceptionTag()
        : _importExceptionTag(module);
  }

  /// Creates a [w.Tag] for a void [w.FunctionType] with two parameters,
  /// a [topInfo.nonNullableType] parameter to hold an exception, and a
  /// [stackTraceInfo.nonNullableType] to hold a stack trace. This single
  /// exception tag is used to throw and catch all Dart exceptions.
  w.Tag _defineExceptionTag() {
    final cachedTag = _exceptionTag[translator.mainModule];
    if (cachedTag != null) return cachedTag;
    final w.FunctionType tagType = translator.typesBuilder.defineFunction([
      translator.topInfo.nonNullableType,
      translator.stackTraceInfo.repr.nonNullableType
    ], const []);
    w.Tag tag = translator.mainModule.tags.define(tagType);
    if (translator.hasMultipleModules) {
      translator.mainModule.exports.export(_exceptionTagName, tag);
    }
    return _exceptionTag[translator.mainModule] = tag;
  }

  w.Tag _importExceptionTag(w.ModuleBuilder module) {
    // Make sure the tag is defined and exported from main.
    final cachedTag = _exceptionTag[module];
    if (cachedTag != null) return cachedTag;

    final mainTag = _defineExceptionTag();
    return _exceptionTag[module] = module.tags.import(
        translator.nameForModule(translator.mainModule),
        _exceptionTagName,
        mainTag.type);
  }
}
