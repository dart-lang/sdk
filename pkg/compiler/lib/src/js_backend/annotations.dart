// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend.annotations;

import '../common.dart';
import '../common_elements.dart' show CommonElements;
import '../compiler.dart' show Compiler;
import '../constants/values.dart';
import '../elements/elements.dart';

/// Handling of special annotations for tests.
class OptimizerHintsForTests {
  final Compiler _compiler;

  OptimizerHintsForTests(this._compiler);

  CommonElements get _commonElements => _compiler.commonElements;

  /// Returns `true` if inlining is disabled for [element].
  bool noInline(Element element) {
    if (_hasAnnotation(element, _commonElements.expectNoInlineClass)) {
      // TODO(floitsch): restrict to elements from the test directory.
      return true;
    }
    return _hasAnnotation(element, _commonElements.noInlineClass);
  }

  /// Returns `true` if parameter and returns types should be trusted for
  /// [element].
  bool trustTypeAnnotations(Element element) {
    return _hasAnnotation(
        element, _commonElements.expectTrustTypeAnnotationsClass);
  }

  /// Returns `true` if inference of parameter types is disabled for [element].
  bool assumeDynamic(Element element) {
    return _hasAnnotation(element, _commonElements.expectAssumeDynamicClass);
  }

  /// Returns `true` if [element] is annotated with [annotationClass].
  bool _hasAnnotation(Element element, ClassElement annotationClass) {
    if (annotationClass == null) return false;
    return _compiler.reporter.withCurrentElement(element, () {
      for (MetadataAnnotation metadata in element.metadata) {
        assert(invariant(metadata, metadata.constant != null,
            message: "Unevaluated metadata constant."));
        ConstantValue value =
            _compiler.constants.getConstantValue(metadata.constant);
        if (value.isConstructedObject) {
          ConstructedConstantValue constructedConstant = value;
          if (constructedConstant.type.element == annotationClass) {
            return true;
          }
        }
      }
      return false;
    });
  }
}
