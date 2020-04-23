// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common_elements.dart' show CommonElements;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/types.dart';
import '../native/behavior.dart';
import '../universe/selector.dart' show Selector;
import '../world.dart' show JClosedWorld;

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
    return results.resultOfParameter(element) ??
        results.closedWorld.abstractValueDomain.dynamicType;
  }

  static AbstractValue inferredResultTypeForSelector(Selector selector,
      AbstractValue receiver, GlobalTypeInferenceResults results) {
    return results.resultTypeOfSelector(selector, receiver) ??
        results.closedWorld.abstractValueDomain.dynamicType;
  }

  static AbstractValue fromNativeBehavior(
      NativeBehavior nativeBehavior, JClosedWorld closedWorld) {
    AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
    var typesReturned = nativeBehavior.typesReturned;
    if (typesReturned.isEmpty) return abstractValueDomain.dynamicType;

    CommonElements commonElements = closedWorld.commonElements;

    // [type] is either an instance of [DartType] or special objects
    // like [native.SpecialType.JsObject].
    AbstractValue fromNativeType(dynamic type) {
      if (type == SpecialType.JsObject) {
        return abstractValueDomain
            .createNonNullExact(commonElements.objectClass);
      } else if (type is VoidType) {
        return abstractValueDomain.nullType;
      } else if (closedWorld.dartTypes.isTopType(type)) {
        return abstractValueDomain.dynamicType;
      } else if (type == commonElements.nullType) {
        return abstractValueDomain.nullType;
      } else {
        return abstractValueDomain.createNonNullSubtype(type.element);
      }
    }

    AbstractValue result =
        abstractValueDomain.unionOfMany(typesReturned.map(fromNativeType));
    assert(abstractValueDomain.isEmpty(result).isPotentiallyFalse,
        "Unexpected empty return value for $nativeBehavior.");
    return result;
  }
}
