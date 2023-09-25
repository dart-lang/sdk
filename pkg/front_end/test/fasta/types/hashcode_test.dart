// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:kernel/kernel.dart';

FunctionType createVoidToR() {
  StructuralParameter R = StructuralParameter("R", const DynamicType());
  return new FunctionType([],
      new StructuralParameterType(R, Nullability.legacy), Nullability.legacy,
      typeParameters: [R]);
}

FunctionType createTTo_VoidToR() {
  StructuralParameter T = new StructuralParameter("T", const DynamicType());
  return new FunctionType([new StructuralParameterType(T, Nullability.legacy)],
      createVoidToR(), Nullability.legacy,
      typeParameters: [T]);
}

void test1() {
  DartType voidToR1 = createVoidToR();
  DartType voidToR2 = createVoidToR();
  DartType voidToR3 = createTTo_VoidToR().returnType;
  Expect.equals(voidToR1.hashCode, voidToR2.hashCode,
      "Hash code mismatch for voidToR1 vs voidToR2."); // true
  Expect.equals(voidToR3, voidToR2); // true
  Expect.equals(voidToR2.hashCode, voidToR3.hashCode,
      "Hash code mismatch for voidToR2 vs voidToR3."); // true, good!

  // Get hash code first to force computing and caching the hashCode recursively
  DartType voidToR4 = (createTTo_VoidToR()..hashCode).returnType;
  Expect.equals(voidToR4, voidToR2); // true
  Expect.equals(voidToR2.hashCode, voidToR4.hashCode,
      "Hash code mismatch for voidToR2 vs voidToR4."); // false, oh no!
}

FunctionType createVoidTo_VoidToR() {
  StructuralParameter R = new StructuralParameter("R", const DynamicType());
  return new FunctionType(
      [],
      new FunctionType([], new StructuralParameterType(R, Nullability.legacy),
          Nullability.legacy),
      Nullability.legacy,
      typeParameters: [R]);
}

void test2() {
  FunctionType outer1 = createVoidTo_VoidToR();
  FunctionType outer2 = createVoidTo_VoidToR();
  DartType voidToR1 = outer1.returnType;
  DartType voidToR2 = outer2.returnType;
  outer2.hashCode; // Trigger hashCode caching
  Expect.equals(outer1, outer2); // true
  Expect.equals(voidToR1.hashCode, voidToR2.hashCode,
      "Hash code mismatch for voidToR1 vs voidToR2."); // false, OK
  Expect.equals(outer1.hashCode, outer2.hashCode,
      "Hash code mismatch for outer1 vs outer2."); // false, on no!
}

void main() {
  test2();
}
