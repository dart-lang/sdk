// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types.constants;

import '../../constants/constant_system.dart' as constant_system;
import '../../constants/values.dart';
import '../../world.dart' show JClosedWorld;
import 'masks.dart';

/// Computes the [TypeMask] for the constant [value].
TypeMask computeTypeMask(CommonMasks abstractValueDomain,
    JClosedWorld closedWorld, ConstantValue value) {
  return value.accept(ConstantValueTypeMasks(abstractValueDomain), closedWorld);
}

class ConstantValueTypeMasks
    extends ConstantValueVisitor<TypeMask, JClosedWorld> {
  final CommonMasks _abstractValueDomain;
  const ConstantValueTypeMasks(this._abstractValueDomain);

  @override
  TypeMask visitConstructed(
      ConstructedConstantValue constant, JClosedWorld closedWorld) {
    if (closedWorld.interceptorData.isInterceptedClass(constant.type.element)) {
      return _abstractValueDomain.nonNullType;
    }
    return new TypeMask.nonNullExact(constant.type.element, closedWorld);
  }

  @override
  TypeMask visitDeferredGlobal(
      DeferredGlobalConstantValue constant, JClosedWorld closedWorld) {
    return constant.referenced.accept(this, closedWorld);
  }

  @override
  TypeMask visitDouble(DoubleConstantValue constant, JClosedWorld closedWorld) {
    // We have to recognize double constants that are 'is int'.
    if (constant_system.isInt(constant)) {
      if (constant.isMinusZero) {
        return _abstractValueDomain.uint31Type;
      } else {
        assert(constant.isPositiveInfinity || constant.isNegativeInfinity);
        return _abstractValueDomain.intType;
      }
    }
    return _abstractValueDomain.doubleType;
  }

  @override
  TypeMask visitDummyInterceptor(
      DummyInterceptorConstantValue constant, JClosedWorld closedWorld) {
    return _abstractValueDomain.dynamicType;
  }

  @override
  TypeMask visitUnreachable(
      UnreachableConstantValue constant, JClosedWorld closedWorld) {
    return _abstractValueDomain.emptyType;
  }

  @override
  TypeMask visitJsName(JsNameConstantValue constant, JClosedWorld closedWorld) {
    return _abstractValueDomain.stringType;
  }

  @override
  TypeMask visitBool(BoolConstantValue constant, JClosedWorld closedWorld) {
    return _abstractValueDomain.boolType;
  }

  @override
  TypeMask visitFunction(
      FunctionConstantValue constant, JClosedWorld closedWorld) {
    return _abstractValueDomain.functionType;
  }

  @override
  TypeMask visitInstantiation(
      InstantiationConstantValue constant, JClosedWorld closedWorld) {
    return _abstractValueDomain.functionType;
  }

  @override
  TypeMask visitInt(IntConstantValue constant, JClosedWorld closedWorld) {
    if (constant.isUInt31()) return _abstractValueDomain.uint31Type;
    if (constant.isUInt32()) return _abstractValueDomain.uint32Type;
    if (constant.isPositive()) return _abstractValueDomain.positiveIntType;
    return _abstractValueDomain.intType;
  }

  @override
  TypeMask visitInterceptor(
      InterceptorConstantValue constant, JClosedWorld closedWorld) {
    return _abstractValueDomain.nonNullType;
  }

  @override
  TypeMask visitList(ListConstantValue constant, JClosedWorld closedWorld) {
    return _abstractValueDomain.constListType;
  }

  @override
  TypeMask visitSet(SetConstantValue constant, JClosedWorld closedWorld) {
    return _abstractValueDomain.constSetType;
  }

  @override
  TypeMask visitMap(MapConstantValue constant, JClosedWorld closedWorld) {
    return _abstractValueDomain.constMapType;
  }

  @override
  TypeMask visitNull(NullConstantValue constant, JClosedWorld closedWorld) {
    return _abstractValueDomain.nullType;
  }

  @override
  TypeMask visitNonConstant(
      NonConstantValue constant, JClosedWorld closedWorld) {
    return _abstractValueDomain.nullType;
  }

  @override
  TypeMask visitString(StringConstantValue constant, JClosedWorld closedWorld) {
    return _abstractValueDomain.stringType;
  }

  @override
  TypeMask visitType(TypeConstantValue constant, JClosedWorld closedWorld) {
    return _abstractValueDomain.typeType;
  }
}
