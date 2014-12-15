// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types.constants;

import '../constants/values.dart';
import '../dart2jslib.dart';
import 'types.dart';

/// Computes the [TypeMask] for the constant [value].
TypeMask computeTypeMask(Compiler compiler, ConstantValue value) {
  return value.accept(const ConstantValueTypeMasks(), compiler);
}

class ConstantValueTypeMasks extends ConstantValueVisitor<TypeMask, Compiler> {
  const ConstantValueTypeMasks();

  @override
  TypeMask visitConstructed(ConstructedConstantValue constant,
                            Compiler compiler) {
    if (compiler.backend.isInterceptorClass(constant.type.element)) {
      return compiler.typesTask.nonNullType;
    }
    return new TypeMask.nonNullExact(constant.type.element, compiler.world);
  }

  @override
  TypeMask visitDeferred(DeferredConstantValue constant, Compiler compiler) {
    return constant.referenced.accept(this, compiler);
  }

  @override
  TypeMask visitDouble(DoubleConstantValue constant, Compiler compiler) {
    // We have to distinguish -0.0 from 0, but for all practical purposes
    // -0.0 is an integer.
    // TODO(17235): this kind of special casing should only happen in the
    // backend.
    if (constant.isMinusZero &&
        compiler.backend.constantSystem.isInt(constant)) {
      return compiler.typesTask.uint31Type;
    }
    assert(!compiler.backend.constantSystem.isInt(constant));
    return compiler.typesTask.doubleType;
  }

  @override
  TypeMask visitDummy(DummyConstantValue constant, Compiler compiler) {
    return constant.typeMask;
  }

  @override
  TypeMask visitBool(BoolConstantValue constant, Compiler compiler) {
    return compiler.typesTask.boolType;
  }

  @override
  TypeMask visitFunction(FunctionConstantValue constant, Compiler compiler) {
    return compiler.typesTask.functionType;
  }

  @override
  TypeMask visitInt(IntConstantValue constant, Compiler compiler) {
    if (constant.isUInt31()) return compiler.typesTask.uint31Type;
    if (constant.isUInt32()) return compiler.typesTask.uint32Type;
    if (constant.isPositive()) return compiler.typesTask.positiveIntType;
    return compiler.typesTask.intType;
  }

  @override
  TypeMask visitInterceptor(InterceptorConstantValue constant,
                            Compiler compiler) {
    return compiler.typesTask.nonNullType;
  }

  @override
  TypeMask visitList(ListConstantValue constant, Compiler compiler) {
    return compiler.typesTask.constListType;
  }

  @override
  TypeMask visitMap(MapConstantValue constant, Compiler compiler) {
    return compiler.typesTask.constMapType;
  }

  @override
  TypeMask visitNull(NullConstantValue constant, Compiler compiler) {
    return compiler.typesTask.nullType;
  }

  @override
  TypeMask visitString(StringConstantValue constant, Compiler compiler) {
    return compiler.typesTask.stringType;
  }

  @override
  TypeMask visitType(TypeConstantValue constant, Compiler compiler) {
    return compiler.typesTask.typeType;
  }
}
