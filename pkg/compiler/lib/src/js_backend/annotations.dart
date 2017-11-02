// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend.backend.annotations;

import '../common_elements.dart' show CommonElements, ElementEnvironment;
import '../constants/values.dart';
import '../elements/entities.dart';

/// Returns `true` if inlining is disabled for [element].
bool noInline(ElementEnvironment elementEnvironment,
    CommonElements commonElements, MemberEntity element) {
  if (_hasAnnotation(
      elementEnvironment, element, commonElements.metaNoInlineClass)) {
    return true;
  }
  if (_hasAnnotation(
      elementEnvironment, element, commonElements.expectNoInlineClass)) {
    // TODO(floitsch): restrict to elements from the test directory.
    return true;
  }
  return _hasAnnotation(
      elementEnvironment, element, commonElements.noInlineClass);
}

/// Returns `true` if inlining is requested for [element].
bool tryInline(ElementEnvironment elementEnvironment,
    CommonElements commonElements, MemberEntity element) {
  if (_hasAnnotation(
      elementEnvironment, element, commonElements.metaTryInlineClass)) {
    return true;
  }
  return false;
}

/// Returns `true` if parameter and returns types should be trusted for
/// [element].
bool trustTypeAnnotations(ElementEnvironment elementEnvironment,
    CommonElements commonElements, MemberEntity element) {
  return _hasAnnotation(elementEnvironment, element,
      commonElements.expectTrustTypeAnnotationsClass);
}

/// Returns `true` if inference of parameter types is disabled for [element].
bool assumeDynamic(ElementEnvironment elementEnvironment,
    CommonElements commonElements, MemberEntity element) {
  return _hasAnnotation(
      elementEnvironment, element, commonElements.expectAssumeDynamicClass);
}

/// Returns `true` if [element] is annotated with [annotationClass].
bool _hasAnnotation(ElementEnvironment elementEnvironment, MemberEntity element,
    ClassEntity annotationClass) {
  if (annotationClass == null) return false;
  for (ConstantValue value in elementEnvironment.getMemberMetadata(element)) {
    if (value.isConstructedObject) {
      ConstructedConstantValue constructedConstant = value;
      if (constructedConstant.type.element == annotationClass) {
        return true;
      }
    }
  }
  return false;
}
