// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Signature conformance test.
abstract mixin class CII {
  int id(int x);
}

mixin CSI {
  String id(int x) => "$x";
}

mixin CIS {
  int id(String x) => 0;
}

mixin CTT<T> {
  T id(T x) => x;
}

// Wrong return type.
abstract class C1 = CII with CIS;
//             ^
// [cfe] The mixin application class 'C1' introduces an erroneous override of 'id'.
//                           ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class C2 extends CII with CIS {}
//             ^
// [cfe] Applying the mixin 'CIS' to 'CII' introduces an erroneous override of 'id'.
//                                 ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE


// Wrong argument type.
abstract class C3 = CII with CSI;
//             ^
// [cfe] The mixin application class 'C3' introduces an erroneous override of 'id'.
//                           ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class C4 extends CII with CSI {}
//             ^
// [cfe] Applying the mixin 'CSI' to 'CII' introduces an erroneous override of 'id'.
//                                 ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE

// Similar as the above but using an instantiated class instead.
abstract class C5 = CII with CTT<int>;
abstract class C6 extends CII with CTT<int> {}
abstract class C7  = CII with CTT<String>;
//             ^
// [cfe] The mixin application class 'C7' introduces an erroneous override of 'id'.
//                            ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class C8 extends CII with CTT<String> {}
//             ^
// [cfe] Applying the mixin 'CTT' to 'CII' introduces an erroneous override of 'id'.
//                                 ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE

// Named parameters
abstract class NIIx {
  int? id({int? x}) => x;
}

mixin NIIxy {
  int? id({int? x, int? y}) => y;
}

mixin NIIy {
  int? id({int? y}) => y;
}

mixin NII {
  int? id(int? x) => x;
}

// It's OK to introduce more named parameters.
abstract class N1 = NIIx with NIIxy;
abstract class N2 extends NIIx with NIIxy {}
// It's NOT OK to rename named parameters.
abstract class N3 = NIIx with NIIy;
//             ^
// [cfe] The mixin application class 'N3' introduces an erroneous override of 'id'.
//                            ^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class N4 extends NIIx with NIIy {}
//             ^
// [cfe] Applying the mixin 'NIIy' to 'NIIx' introduces an erroneous override of 'id'.
//                                  ^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE


// It's NOT OK to drop named parameters.
abstract class N5 = NIIx with NII;
//             ^
// [cfe] The mixin application class 'N5' introduces an erroneous override of 'id'.
//                            ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class N6 extends NIIx with NII {}
//             ^
// [cfe] Applying the mixin 'NII' to 'NIIx' introduces an erroneous override of 'id'.
//                                  ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE

mixin NBABxy<A, B> {
  B? id ({A? x, B? y}) => y;
}

mixin NTTy<T> {
  T? id({T? y}) => y;
}

mixin NTTx<T> {
  T? id(T? x) => x;
}

// Same as above but with generic classes.
abstract class N7 = NIIx with NBABxy<int, int>;
abstract class N8 extends NIIx with NBABxy<int, int> {}
abstract class N9 = NIIx with NBABxy<String, int>;
//             ^
// [cfe] The mixin application class 'N9' introduces an erroneous override of 'id'.
//                            ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class N10 extends NIIx with NBABxy<String, int> {}
//             ^
// [cfe] Applying the mixin 'NBABxy' to 'NIIx' introduces an erroneous override of 'id'.
//                                   ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class N11 = NIIx with NTTy<int>;
//             ^
// [cfe] The mixin application class 'N11' introduces an erroneous override of 'id'.
//                             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class N12 extends NIIx with NTTy<int> {}
//             ^
// [cfe] Applying the mixin 'NTTy' to 'NIIx' introduces an erroneous override of 'id'.
//                                   ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class N13 = NIIx with NTTx<int>;
//             ^
// [cfe] The mixin application class 'N13' introduces an erroneous override of 'id'.
//                             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class N14 extends NIIx with NTTx<int> {}
//             ^
// [cfe] Applying the mixin 'NTTx' to 'NIIx' introduces an erroneous override of 'id'.
//                                   ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE

// Optional positional parameters
abstract class OII {
  int? id([int? x]) => x;
}

mixin OIII {
  int? id([int? x, int? y]) => y;
}

mixin OIIy {
  int? id([int? y]) => y;
}

mixin PII {
  int? id(int? x) => x;
}

// It's OK to introduce more optional parameters.
abstract class O1 = OII with OIII;
abstract class O2 extends OII with OIII {}
// It's OK to rename optional parameters.
abstract class O3 = OII with OIIy;
abstract class O4 extends OII with OIIy {}
// It's NOT OK to drop optional parameters.
abstract class O5 = OII with PII;
//             ^
// [cfe] The mixin application class 'O5' introduces an erroneous override of 'id'.
//                           ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class O6 extends OII with PII {}
//             ^
// [cfe] Applying the mixin 'PII' to 'OII' introduces an erroneous override of 'id'.
//                                 ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE

mixin OBAB<A, B> {
  B? id ([A? x, B? y]) => y;
}

mixin OTTy<T> {
  T? id([T? y]) => y;
}

mixin PTT<T> {
  T? id(T? x) => x;
}

// Same as above but with generic classes.
abstract class O7 = OII with OBAB<int, int>;
abstract class O8 extends OII with OBAB<int, int> {}
abstract class O9 = OII with OBAB<String, int>;
//             ^
// [cfe] The mixin application class 'O9' introduces an erroneous override of 'id'.
//                           ^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class O10 extends OII with OBAB<String, int> {}
//             ^
// [cfe] Applying the mixin 'OBAB' to 'OII' introduces an erroneous override of 'id'.
//                                  ^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class O11 = OII with OTTy<int>;
abstract class O12 extends OII with OTTy<int> {}
abstract class O13 = OII with PTT<int>;
//             ^
// [cfe] The mixin application class 'O13' introduces an erroneous override of 'id'.
//                            ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class O14 extends OII with PTT<int> {}
//             ^
// [cfe] Applying the mixin 'PTT' to 'OII' introduces an erroneous override of 'id'.
//                                  ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE

// More tests with generic classes.
abstract class GTTnum {
  T id<T extends num>(x);
}

mixin MTTnum {
  T id<T extends num>(x) => x;
}

mixin MTTint {
  T id<T extends int>(x) => x;
}

mixin MTT {
  T id<T>(x) => x;
}

mixin MTTnumR {
  T id<T extends num, R>(x) => x;
}
class G1 = GTTnum with MTTnum;
class G2 = GTTnum with MTTint;
//    ^
// [cfe] The mixin application class 'G2' introduces an erroneous override of 'id'.
//                     ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
class G3 = GTTnum with MTT;
//    ^
// [cfe] The mixin application class 'G3' introduces an erroneous override of 'id'.
//                     ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
class G4 = GTTnum with MTTnumR;
//    ^
// [cfe] The mixin application class 'G4' introduces an erroneous override of 'id'.
//                     ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
class G5 = GTTnum with CII;
//    ^^
// [analyzer] COMPILE_TIME_ERROR.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER
// [cfe] The mixin application class 'G5' introduces an erroneous override of 'id'.
//    ^
// [cfe] The non-abstract class 'G5' is missing implementations for these members:
//                     ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE

void main() {}
