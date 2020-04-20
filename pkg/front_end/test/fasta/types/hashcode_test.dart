import 'package:expect/expect.dart';
import 'package:kernel/kernel.dart';

FunctionType createVoidToR() {
  TypeParameter R = TypeParameter("R", const DynamicType());
  return new FunctionType(
      [], new TypeParameterType(R, Nullability.legacy), Nullability.legacy,
      typeParameters: [R]);
}

FunctionType createTTo_VoidToR() {
  TypeParameter T = new TypeParameter("T", const DynamicType());
  return new FunctionType([new TypeParameterType(T, Nullability.legacy)],
      createVoidToR(), Nullability.legacy,
      typeParameters: [T]);
}

test1() {
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
  TypeParameter R = new TypeParameter("R", const DynamicType());
  return new FunctionType(
      [],
      new FunctionType(
          [], new TypeParameterType(R, Nullability.legacy), Nullability.legacy),
      Nullability.legacy,
      typeParameters: [R]);
}

test2() {
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

main() {
  test2();
}
