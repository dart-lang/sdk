// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart' show CommonElements;
import '../elements/entities.dart';
import '../native/native.dart' as native;
import '../types/abstract_value_domain.dart';
import '../types/types.dart';
import '../universe/selector.dart' show Selector;
import '../world.dart' show ClosedWorld;

class AbstractValueFactory {
  static AbstractValue inferredReturnTypeForElement(
      FunctionEntity element, GlobalTypeInferenceResults results) {
    return results.resultOfMember(element).returnType ??
        results.closedWorld.abstractValueDomain.dynamicType;
  }

  static AbstractValue inferredTypeForMember(
      MemberEntity element, GlobalTypeInferenceResults results) {
    return results.resultOfMember(element).type ??
        results.closedWorld.abstractValueDomain.dynamicType;
  }

  static AbstractValue inferredTypeForParameter(
      Local element, GlobalTypeInferenceResults results) {
    return results.resultOfParameter(element).type ??
        results.closedWorld.abstractValueDomain.dynamicType;
  }

  static AbstractValue inferredTypeForSelector(Selector selector,
      AbstractValue receiver, GlobalTypeInferenceResults results) {
    return results.typeOfSelector(selector, receiver) ??
        results.closedWorld.abstractValueDomain.dynamicType;
  }

  static AbstractValue fromNativeBehavior(
      native.NativeBehavior nativeBehavior, ClosedWorld closedWorld) {
    AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
    var typesReturned = nativeBehavior.typesReturned;
    if (typesReturned.isEmpty) return abstractValueDomain.dynamicType;

    CommonElements commonElements = closedWorld.commonElements;

    // [type] is either an instance of [DartType] or special objects
    // like [native.SpecialType.JsObject].
    AbstractValue fromNativeType(dynamic type) {
      if (type == native.SpecialType.JsObject) {
        return abstractValueDomain
            .createNonNullExact(commonElements.objectClass);
      } else if (type.isVoid) {
        return abstractValueDomain.nullType;
      } else if (type.isDynamic) {
        return abstractValueDomain.dynamicType;
      } else if (type == commonElements.nullType) {
        return abstractValueDomain.nullType;
      } else if (type.treatAsDynamic) {
        return abstractValueDomain.dynamicType;
      } else {
        return abstractValueDomain.createNonNullSubtype(type.element);
      }
    }

    AbstractValue result =
        abstractValueDomain.unionOfMany(typesReturned.map(fromNativeType));
    assert(!abstractValueDomain.isEmpty(result));
    return result;
  }
}
