// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests bounds checking for extension methods

extension E1<T extends num> on T {
  int get e1 => 1;
}

extension E2<T extends S, S extends num> on T {
  int get e2 => 2;
}

extension E3<T> on T {
  S f3<S extends T>(S x) => x;
}

extension E4<T extends Rec<T>> on T {
  int get e4 => 4;
}

class Rec<T extends Rec<T>> {}

class RecSolution extends Rec<RecSolution> {}

void main() {
  String s = "s";
  int i = 0;
  double d = 1.0;

  // Inferred type of String does not satisfy the bound.
  s.e1;
//  ^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
// [cfe] The getter 'e1' isn't defined for the class 'String'.
  E1(s).e1;
//^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'E1|get#e1'.
  E1<String>(s).e1;
//^
// [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'E1|get#e1'.
//   ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

  // Inferred types of int and double are ok
  i.e1;
  E1(i).e1;
  E1<int>(i).e1;
  d.e1;
  E1(d).e1;
  E1<double>(d).e1;

  // Inferred type of String does not satisfy the bound.
  s.e2;
//  ^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
// [cfe] The getter 'e2' isn't defined for the class 'String'.
  E2(s).e2;
//^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'String' doesn't conform to the bound 'S' of the type variable 'T' on 'E2|get#e2'.
  E2<String, num>(s).e2;
//^
// [cfe] Type argument 'String' doesn't conform to the bound 'S' of the type variable 'T' on 'E2|get#e2'.
//   ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

  // Inferred types of int and double are ok
  i.e2;
  E2(i).e2;
  E2<int, num>(i).e2;
  d.e2;
  E2(d).e2;
  E2<double, num>(d).e2;

  // Inferred type int for method type parameter doesn't match the inferred
  // bound of String
  s.f3(3);
//  ^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'int' doesn't conform to the bound 'T' of the type variable 'S' on 'E3|f3'.
  E3(s).f3(3);
//      ^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'int' doesn't conform to the bound 'T' of the type variable 'S' on 'E3|f3'.
  E3<String>(s).f3(3);
//              ^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'int' doesn't conform to the bound 'T' of the type variable 'S' on 'E3|f3'.

  // Inferred type int for method type parameter is ok
  i.f3(3);
  E3(i).f3(3);
  E3<int>(i).f3(3);

  // Inferred type int for method type parameter doesn't match the inferred
  // bound of double
  d.f3(3);
//  ^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'int' doesn't conform to the bound 'T' of the type variable 'S' on 'E3|f3'.
  E3(d).f3(3);
//      ^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'int' doesn't conform to the bound 'T' of the type variable 'S' on 'E3|f3'.
  E3<double>(d).f3(3);
//              ^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'int' doesn't conform to the bound 'T' of the type variable 'S' on 'E3|f3'.

  RecSolution recs = RecSolution();
  Rec<dynamic> superRec = RecSolution(); // Super-bounded type.

  // Inferred type of RecSolution is ok
  recs.e4;
  E4(recs).e4;
  E4<RecSolution>(recs).e4;

  // Inferred super-bounded type is invalid as type argument
  superRec.e4;
//         ^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
// [cfe] The getter 'e4' isn't defined for the class 'Rec<dynamic>'.
  E4(superRec).e4;
//^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'Rec<dynamic>' doesn't conform to the bound 'Rec<T>' of the type variable 'T' on 'E4|get#e4'.
  E4<Rec<dynamic>>(superRec).e4;
//^
// [cfe] Type argument 'Rec<dynamic>' doesn't conform to the bound 'Rec<T>' of the type variable 'T' on 'E4|get#e4'.
//   ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
}
