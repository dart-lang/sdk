// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend.annotations;

import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../constants/values.dart';
import '../elements/entities.dart';

/// Handling of special annotations for tests.
class OptimizerHintsForTests {
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;

  OptimizerHintsForTests(this._elementEnvironment, this._commonElements);

  /// Returns `true` if inlining is disabled for [element].
  bool noInline(MemberEntity element) {
    if (_hasAnnotation(element, _commonElements.expectNoInlineClass)) {
      // TODO(floitsch): restrict to elements from the test directory.
      return true;
    }
    return _hasAnnotation(element, _commonElements.noInlineClass);
  }

  /// Returns `true` if parameter and returns types should be trusted for
  /// [element].
  bool trustTypeAnnotations(MemberEntity element) {
    return _hasAnnotation(
        element, _commonElements.expectTrustTypeAnnotationsClass);
  }

  /// Returns `true` if inference of parameter types is disabled for [element].
  bool assumeDynamic(MemberEntity element) {
    return _hasAnnotation(element, _commonElements.expectAssumeDynamicClass);
  }

  /// Returns `true` if [element] is annotated with [annotationClass].
  bool _hasAnnotation(MemberEntity element, ClassEntity annotationClass) {
    if (annotationClass == null) return false;
    for (ConstantValue value
        in _elementEnvironment.getMemberMetadata(element)) {
      if (value.isConstructedObject) {
        ConstructedConstantValue constructedConstant = value;
        if (constructedConstant.type.element == annotationClass) {
          return true;
        }
      }
    }
    return false;
  }
}
