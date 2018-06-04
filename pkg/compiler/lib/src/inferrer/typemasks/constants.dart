// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types.constants;

import '../../common.dart';
import '../../constants/values.dart';
import '../../js_backend/js_backend.dart' show SyntheticConstantKind;
import '../../world.dart' show JClosedWorld;
import 'masks.dart';

/// Computes the [TypeMask] for the constant [value].
TypeMask computeTypeMask(JClosedWorld closedWorld, ConstantValue value) {
  return value.accept(const ConstantValueTypeMasks(), closedWorld);
}

class ConstantValueTypeMasks
    extends ConstantValueVisitor<TypeMask, JClosedWorld> {
  const ConstantValueTypeMasks();

  @override
  TypeMask visitConstructed(
      ConstructedConstantValue constant, JClosedWorld closedWorld) {
    if (closedWorld.interceptorData.isInterceptedClass(constant.type.element)) {
      return closedWorld.abstractValueDomain.nonNullType;
    }
    return new TypeMask.nonNullExact(constant.type.element, closedWorld);
  }

  @override
  TypeMask visitDeferred(
      DeferredConstantValue constant, JClosedWorld closedWorld) {
    return constant.referenced.accept(this, closedWorld);
  }

  @override
  TypeMask visitDeferredGlobal(
      DeferredGlobalConstantValue constant, JClosedWorld closedWorld) {
    return constant.referenced.accept(this, closedWorld);
  }

  @override
  TypeMask visitDouble(DoubleConstantValue constant, JClosedWorld closedWorld) {
    // We have to recognize double constants that are 'is int'.
    if (closedWorld.constantSystem.isInt(constant)) {
      if (constant.isMinusZero) {
        return closedWorld.abstractValueDomain.uint31Type;
      } else {
        assert(constant.isPositiveInfinity || constant.isNegativeInfinity);
        return closedWorld.abstractValueDomain.intType;
      }
    }
    return closedWorld.abstractValueDomain.doubleType;
  }

  @override
  TypeMask visitSynthetic(
      SyntheticConstantValue constant, JClosedWorld closedWorld) {
    switch (constant.valueKind) {
      case SyntheticConstantKind.DUMMY_INTERCEPTOR:
        return constant.payload;
      case SyntheticConstantKind.EMPTY_VALUE:
        return constant.payload;
      case SyntheticConstantKind.TYPEVARIABLE_REFERENCE:
        return closedWorld.abstractValueDomain.intType;
      case SyntheticConstantKind.NAME:
        return closedWorld.abstractValueDomain.stringType;
      default:
        throw failedAt(CURRENT_ELEMENT_SPANNABLE,
            "Unexpected DummyConstantKind: ${constant.toStructuredText()}.");
    }
  }

  @override
  TypeMask visitBool(BoolConstantValue constant, JClosedWorld closedWorld) {
    return closedWorld.abstractValueDomain.boolType;
  }

  @override
  TypeMask visitFunction(
      FunctionConstantValue constant, JClosedWorld closedWorld) {
    return closedWorld.abstractValueDomain.functionType;
  }

  @override
  TypeMask visitInstantiation(
      InstantiationConstantValue constant, JClosedWorld closedWorld) {
    return closedWorld.abstractValueDomain.functionType;
  }

  @override
  TypeMask visitInt(IntConstantValue constant, JClosedWorld closedWorld) {
    if (constant.isUInt31()) return closedWorld.abstractValueDomain.uint31Type;
    if (constant.isUInt32()) return closedWorld.abstractValueDomain.uint32Type;
    if (constant.isPositive())
      return closedWorld.abstractValueDomain.positiveIntType;
    return closedWorld.abstractValueDomain.intType;
  }

  @override
  TypeMask visitInterceptor(
      InterceptorConstantValue constant, JClosedWorld closedWorld) {
    return closedWorld.abstractValueDomain.nonNullType;
  }

  @override
  TypeMask visitList(ListConstantValue constant, JClosedWorld closedWorld) {
    return closedWorld.abstractValueDomain.constListType;
  }

  @override
  TypeMask visitMap(MapConstantValue constant, JClosedWorld closedWorld) {
    return closedWorld.abstractValueDomain.constMapType;
  }

  @override
  TypeMask visitNull(NullConstantValue constant, JClosedWorld closedWorld) {
    return closedWorld.abstractValueDomain.nullType;
  }

  @override
  TypeMask visitNonConstant(
      NonConstantValue constant, JClosedWorld closedWorld) {
    return closedWorld.abstractValueDomain.nullType;
  }

  @override
  TypeMask visitString(StringConstantValue constant, JClosedWorld closedWorld) {
    return closedWorld.abstractValueDomain.stringType;
  }

  @override
  TypeMask visitType(TypeConstantValue constant, JClosedWorld closedWorld) {
    return closedWorld.abstractValueDomain.typeType;
  }
}
