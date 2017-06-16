// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart' show CommonElements;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../native/native.dart' as native;
import '../types/types.dart';
import '../universe/selector.dart' show Selector;
import '../world.dart' show ClosedWorld;

class TypeMaskFactory {
  static TypeMask inferredReturnTypeForElement(
      MethodElement element, GlobalTypeInferenceResults results) {
    return results.resultOfMember(element).returnType ??
        results.closedWorld.commonMasks.dynamicType;
  }

  static TypeMask inferredTypeForMember(
      MemberEntity element, GlobalTypeInferenceResults results) {
    // TODO(johnniwinther): Support inferred types for member entities.
    if (element is! MemberElement) {
      return results.closedWorld.commonMasks.dynamicType;
    }
    return results.resultOfMember(element).type ??
        results.closedWorld.commonMasks.dynamicType;
  }

  static TypeMask inferredTypeForParameter(
      ParameterElement element, GlobalTypeInferenceResults results) {
    return results.resultOfParameter(element).type ??
        results.closedWorld.commonMasks.dynamicType;
  }

  static TypeMask inferredTypeForSelector(
      Selector selector, TypeMask mask, GlobalTypeInferenceResults results) {
    return results.typeOfSelector(selector, mask) ??
        results.closedWorld.commonMasks.dynamicType;
  }

  static TypeMask fromNativeBehavior(
      native.NativeBehavior nativeBehavior, ClosedWorld closedWorld) {
    CommonMasks commonMasks = closedWorld.commonMasks;
    var typesReturned = nativeBehavior.typesReturned;
    if (typesReturned.isEmpty) return commonMasks.dynamicType;

    CommonElements commonElements = closedWorld.commonElements;

    // [type] is either an instance of [DartType] or special objects
    // like [native.SpecialType.JsObject].
    TypeMask fromNativeType(dynamic type) {
      if (type == native.SpecialType.JsObject) {
        return new TypeMask.nonNullExact(
            commonElements.objectClass, closedWorld);
      }

      if (type.isVoid) return commonMasks.nullType;
      if (type.element == commonElements.nullClass) return commonMasks.nullType;
      if (type.treatAsDynamic) return commonMasks.dynamicType;
      return new TypeMask.nonNullSubtype(type.element, closedWorld);
    }

    TypeMask result = typesReturned
        .map(fromNativeType)
        .reduce((t1, t2) => t1.union(t2, closedWorld));
    assert(!result.isEmpty);
    return result;
  }
}
