// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library;

import '../../constants/constant_system.dart' as constant_system;
import '../../constants/values.dart';
import '../../js_model/js_world.dart' show JClosedWorld;
import 'masks.dart';

/// Computes the [TypeMask] for the constant [value].
TypeMask computeTypeMask(CommonMasks abstractValueDomain, ConstantValue value) {
  return value.accept(ConstantValueTypeMasks(abstractValueDomain), null);
}

class ConstantValueTypeMasks extends ConstantValueVisitor<TypeMask, Null> {
  final CommonMasks _abstractValueDomain;
  const ConstantValueTypeMasks(this._abstractValueDomain);

  JClosedWorld get closedWorld => _abstractValueDomain.closedWorld;

  @override
  TypeMask visitConstructed(ConstructedConstantValue constant, _) {
    if (closedWorld.interceptorData.isInterceptedClass(constant.type.element)) {
      return _abstractValueDomain.nonNullType;
    }
    return TypeMask.nonNullExact(constant.type.element, _abstractValueDomain);
  }

  @override
  TypeMask visitRecord(RecordConstantValue constant, _) {
    final representation = closedWorld.recordData.representationForShape(
      constant.shape,
    );
    if (representation == null) return _abstractValueDomain.recordType;
    return TypeMask.nonNullExact(representation.cls, _abstractValueDomain);
  }

  @override
  TypeMask visitDeferredGlobal(DeferredGlobalConstantValue constant, _) =>
      constant.referenced.accept(this, null);

  @override
  TypeMask visitDouble(DoubleConstantValue constant, _) {
    // We have to recognize double constants that are 'is int'.
    if (constant_system.isInt(constant)) {
      if (constant.isMinusZero) {
        return _abstractValueDomain.uint31Type;
      }
      assert(constant.isPositiveInfinity || constant.isNegativeInfinity);
      return _abstractValueDomain.intType;
    }
    return _abstractValueDomain.numNotIntType;
  }

  @override
  TypeMask visitDummy(DummyConstantValue constant, _) =>
      _abstractValueDomain.dynamicType;

  @override
  TypeMask visitLateSentinel(LateSentinelConstantValue constant, _) =>
      _abstractValueDomain.lateSentinelType;

  @override
  TypeMask visitUnreachable(UnreachableConstantValue constant, _) =>
      _abstractValueDomain.emptyType;

  @override
  TypeMask visitJsName(JsNameConstantValue constant, _) =>
      _abstractValueDomain.stringType;

  @override
  TypeMask visitBool(BoolConstantValue constant, _) =>
      _abstractValueDomain.boolType;

  @override
  TypeMask visitFunction(FunctionConstantValue constant, _) =>
      _abstractValueDomain.functionType;

  @override
  TypeMask visitInstantiation(InstantiationConstantValue constant, _) =>
      _abstractValueDomain.functionType;

  @override
  TypeMask visitInt(IntConstantValue constant, _) {
    if (constant.isUInt31()) return _abstractValueDomain.uint31Type;
    if (constant.isUInt32()) return _abstractValueDomain.uint32Type;
    if (constant.isPositive()) return _abstractValueDomain.positiveIntType;
    return _abstractValueDomain.intType;
  }

  @override
  TypeMask visitInterceptor(InterceptorConstantValue constant, _) =>
      _abstractValueDomain.nonNullType;

  @override
  TypeMask visitList(ListConstantValue constant, _) =>
      _abstractValueDomain.constListType;

  @override
  TypeMask visitSet(SetConstantValue constant, _) =>
      _abstractValueDomain.constSetType;

  @override
  TypeMask visitMap(MapConstantValue constant, _) =>
      _abstractValueDomain.constMapType;

  @override
  TypeMask visitNull(NullConstantValue constant, _) =>
      _abstractValueDomain.nullType;

  @override
  TypeMask visitString(StringConstantValue constant, _) =>
      _abstractValueDomain.stringType;

  @override
  TypeMask visitType(TypeConstantValue constant, _) =>
      _abstractValueDomain.typeType;

  @override
  TypeMask visitJavaScriptObject(JavaScriptObjectConstantValue constant, _) =>
      // TODO(sra): Change to plain JavaScript object.
      _abstractValueDomain.dynamicType;
}
