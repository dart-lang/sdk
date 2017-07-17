// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types.constants;

import '../common.dart';
import '../constants/values.dart';
import '../js_backend/js_backend.dart' show SyntheticConstantKind;
import '../world.dart' show ClosedWorld;
import 'masks.dart';

/// Computes the [TypeMask] for the constant [value].
TypeMask computeTypeMask(ClosedWorld closedWorld, ConstantValue value) {
  return value.accept(const ConstantValueTypeMasks(), closedWorld);
}

class ConstantValueTypeMasks
    extends ConstantValueVisitor<TypeMask, ClosedWorld> {
  const ConstantValueTypeMasks();

  @override
  TypeMask visitConstructed(
      ConstructedConstantValue constant, ClosedWorld closedWorld) {
    if (closedWorld.interceptorData.isInterceptedClass(constant.type.element)) {
      return closedWorld.commonMasks.nonNullType;
    }
    return new TypeMask.nonNullExact(constant.type.element, closedWorld);
  }

  @override
  TypeMask visitDeferred(
      DeferredConstantValue constant, ClosedWorld closedWorld) {
    return constant.referenced.accept(this, closedWorld);
  }

  @override
  TypeMask visitDouble(DoubleConstantValue constant, ClosedWorld closedWorld) {
    // We have to recognize double constants that are 'is int'.
    if (closedWorld.constantSystem.isInt(constant)) {
      if (constant.isMinusZero) {
        return closedWorld.commonMasks.uint31Type;
      } else {
        assert(constant.isPositiveInfinity || constant.isNegativeInfinity);
        return closedWorld.commonMasks.intType;
      }
    }
    return closedWorld.commonMasks.doubleType;
  }

  @override
  TypeMask visitSynthetic(
      SyntheticConstantValue constant, ClosedWorld closedWorld) {
    switch (constant.valueKind) {
      case SyntheticConstantKind.DUMMY_INTERCEPTOR:
        return constant.payload;
      case SyntheticConstantKind.EMPTY_VALUE:
        return constant.payload;
      case SyntheticConstantKind.TYPEVARIABLE_REFERENCE:
        return closedWorld.commonMasks.intType;
      case SyntheticConstantKind.NAME:
        return closedWorld.commonMasks.stringType;
      default:
        throw failedAt(CURRENT_ELEMENT_SPANNABLE,
            "Unexpected DummyConstantKind: ${constant.toStructuredText()}.");
    }
  }

  @override
  TypeMask visitBool(BoolConstantValue constant, ClosedWorld closedWorld) {
    return closedWorld.commonMasks.boolType;
  }

  @override
  TypeMask visitFunction(
      FunctionConstantValue constant, ClosedWorld closedWorld) {
    return closedWorld.commonMasks.functionType;
  }

  @override
  TypeMask visitInt(IntConstantValue constant, ClosedWorld closedWorld) {
    if (constant.isUInt31()) return closedWorld.commonMasks.uint31Type;
    if (constant.isUInt32()) return closedWorld.commonMasks.uint32Type;
    if (constant.isPositive()) return closedWorld.commonMasks.positiveIntType;
    return closedWorld.commonMasks.intType;
  }

  @override
  TypeMask visitInterceptor(
      InterceptorConstantValue constant, ClosedWorld closedWorld) {
    return closedWorld.commonMasks.nonNullType;
  }

  @override
  TypeMask visitList(ListConstantValue constant, ClosedWorld closedWorld) {
    return closedWorld.commonMasks.constListType;
  }

  @override
  TypeMask visitMap(MapConstantValue constant, ClosedWorld closedWorld) {
    return closedWorld.commonMasks.constMapType;
  }

  @override
  TypeMask visitNull(NullConstantValue constant, ClosedWorld closedWorld) {
    return closedWorld.commonMasks.nullType;
  }

  @override
  TypeMask visitNonConstant(
      NonConstantValue constant, ClosedWorld closedWorld) {
    return closedWorld.commonMasks.nullType;
  }

  @override
  TypeMask visitString(StringConstantValue constant, ClosedWorld closedWorld) {
    return closedWorld.commonMasks.stringType;
  }

  @override
  TypeMask visitType(TypeConstantValue constant, ClosedWorld closedWorld) {
    return closedWorld.commonMasks.typeType;
  }
}
