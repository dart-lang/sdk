// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../compiler.dart' show Compiler;
import '../core_types.dart' show CoreClasses;
import '../elements/elements.dart';
import '../native/native.dart' as native;
import '../tree/tree.dart' as ast;
import '../types/types.dart';
import '../universe/selector.dart' show Selector;
import '../world.dart' show ClosedWorld;

class TypeMaskFactory {
  static TypeMask inferredReturnTypeForElement(
      Element element, Compiler compiler) {
    return compiler.globalInference.results.resultOf(element).returnType ??
        compiler.closedWorld.commonMasks.dynamicType;
  }

  static TypeMask inferredTypeForElement(Element element, Compiler compiler) {
    return compiler.globalInference.results.resultOf(element).type ??
        compiler.closedWorld.commonMasks.dynamicType;
  }

  static TypeMask inferredTypeForSelector(
      Selector selector, TypeMask mask, Compiler compiler) {
    return compiler.globalInference.results.typeOfSelector(selector, mask) ??
        compiler.closedWorld.commonMasks.dynamicType;
  }

  static TypeMask fromNativeBehavior(
      native.NativeBehavior nativeBehavior, Compiler compiler) {
    ClosedWorld closedWorld = compiler.closedWorld;
    CommonMasks commonMasks = closedWorld.commonMasks;
    var typesReturned = nativeBehavior.typesReturned;
    if (typesReturned.isEmpty) return commonMasks.dynamicType;

    CoreClasses coreClasses = closedWorld.coreClasses;

    // [type] is either an instance of [DartType] or special objects
    // like [native.SpecialType.JsObject].
    TypeMask fromNativeType(dynamic type) {
      if (type == native.SpecialType.JsObject) {
        return new TypeMask.nonNullExact(coreClasses.objectClass, closedWorld);
      }

      if (type.isVoid) return commonMasks.nullType;
      if (type.element == coreClasses.nullClass) return commonMasks.nullType;
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
