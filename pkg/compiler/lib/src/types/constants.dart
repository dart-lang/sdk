// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library types.constants;

import '../common.dart';
import '../compiler.dart' show Compiler;
import '../constants/values.dart';
import '../js_backend/js_backend.dart' show SyntheticConstantKind;
import 'types.dart';

/// Computes the [TypeMask] for the constant [value].
TypeMask computeTypeMask(Compiler compiler, ConstantValue value) {
  return value.accept(const ConstantValueTypeMasks(), compiler);
}

class ConstantValueTypeMasks extends ConstantValueVisitor<TypeMask, Compiler> {
  const ConstantValueTypeMasks();

  @override
  TypeMask visitConstructed(
      ConstructedConstantValue constant, Compiler compiler) {
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
    // We have to recognize double constants that are 'is int'.
    if (compiler.backend.constantSystem.isInt(constant)) {
      if (constant.isMinusZero) {
        return compiler.typesTask.uint31Type;
      } else {
        assert(constant.isPositiveInfinity || constant.isNegativeInfinity);
        return compiler.typesTask.intType;
      }
    }
    return compiler.typesTask.doubleType;
  }

  @override
  TypeMask visitSynthetic(SyntheticConstantValue constant, Compiler compiler) {
    switch (constant.kind) {
      case SyntheticConstantKind.DUMMY_INTERCEPTOR:
        return constant.payload;
      case SyntheticConstantKind.EMPTY_VALUE:
        return constant.payload;
      case SyntheticConstantKind.TYPEVARIABLE_REFERENCE:
        return compiler.typesTask.intType;
      case SyntheticConstantKind.NAME:
        return compiler.typesTask.stringType;
      default:
        DiagnosticReporter reporter = compiler.reporter;
        reporter.internalError(
            CURRENT_ELEMENT_SPANNABLE, "Unexpected DummyConstantKind.");
        return null;
    }
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
  TypeMask visitInterceptor(
      InterceptorConstantValue constant, Compiler compiler) {
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
  TypeMask visitNonConstant(NonConstantValue constant, Compiler compiler) {
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
