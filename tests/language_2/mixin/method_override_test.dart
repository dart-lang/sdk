// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Signature conformance test.
abstract class CII {
  int id(int x);
}

class CSI {
  String id(int x) => "$x";
}

class CIS {
  int id(String x) => 0;
}

class CTT<T> {
  T id(T x) => x;
}

// Wrong return type.
abstract class C1 = CII with CIS;
//             ^^
// [cfe] Class 'C1' inherits multiple members named 'id' with incompatible signatures.
//             ^
// [cfe] The mixin application class 'C1' introduces an erroneous override of 'id'.
//                           ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class C2 extends CII with CIS {}
//             ^^
// [cfe] Applying the mixin 'CIS' to 'CII' introduces an erroneous override of 'id'.
//             ^
// [cfe] Class 'CII with CIS' inherits multiple members named 'id' with incompatible signatures.
//                                 ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE


// Wrong argument type.
abstract class C3 = CII with CSI;
//             ^^
// [cfe] Class 'C3' inherits multiple members named 'id' with incompatible signatures.
//             ^
// [cfe] The mixin application class 'C3' introduces an erroneous override of 'id'.
//                           ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class C4 extends CII with CSI {}
//             ^^
// [cfe] Applying the mixin 'CSI' to 'CII' introduces an erroneous override of 'id'.
//             ^
// [cfe] Class 'CII with CSI' inherits multiple members named 'id' with incompatible signatures.
//                                 ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE

// Similar as the above but using an instantiated class instead.
abstract class C5 = CII with CTT<int>;
abstract class C6 extends CII with CTT<int> {}
abstract class C7  = CII with CTT<String>;
//             ^^
// [cfe] Class 'C7' inherits multiple members named 'id' with incompatible signatures.
//             ^
// [cfe] The mixin application class 'C7' introduces an erroneous override of 'id'.
//                            ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class C8 extends CII with CTT<String> {}
//             ^^
// [cfe] Applying the mixin 'CTT' to 'CII' introduces an erroneous override of 'id'.
//             ^
// [cfe] Class 'CII with CTT<String>' inherits multiple members named 'id' with incompatible signatures.
//                                 ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE

// Named parameters
abstract class NIIx {
  int id({int x}) => x;
}

class NIIxy {
  int id({int x, int y}) => y;
}

class NIIy {
  int id({int y}) => y;
}

class NII {
  int id(int x) => x;
}

// It's OK to introduce more named parameters.
abstract class N1 = NIIx with NIIxy;
abstract class N2 extends NIIx with NIIxy {}
// It's NOT OK to rename named parameters.
abstract class N3 = NIIx with NIIy;
//             ^^
// [cfe] Class 'N3' inherits multiple members named 'id' with incompatible signatures.
//             ^
// [cfe] The mixin application class 'N3' introduces an erroneous override of 'id'.
//                            ^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class N4 extends NIIx with NIIy {}
//             ^^
// [cfe] Applying the mixin 'NIIy' to 'NIIx' introduces an erroneous override of 'id'.
//             ^
// [cfe] Class 'NIIx with NIIy' inherits multiple members named 'id' with incompatible signatures.
//                                  ^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE


// It's NOT OK to drop named parameters.
abstract class N5 = NIIx with NII;
//             ^^
// [cfe] Class 'N5' inherits multiple members named 'id' with incompatible signatures.
//             ^
// [cfe] The mixin application class 'N5' introduces an erroneous override of 'id'.
//                            ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class N6 extends NIIx with NII {}
//             ^^
// [cfe] Applying the mixin 'NII' to 'NIIx' introduces an erroneous override of 'id'.
//             ^
// [cfe] Class 'NIIx with NII' inherits multiple members named 'id' with incompatible signatures.
//                                  ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE

class NBABxy<A, B> {
  B id ({A x, B y}) => y;
}

class NTTy<T> {
  T id({T y}) => y;
}

class NTTx<T> {
  T id(T x) => x;
}

// Same as above but with generic classes.
abstract class N7 = NIIx with NBABxy<int, int>;
abstract class N8 extends NIIx with NBABxy<int, int> {}
abstract class N9 = NIIx with NBABxy<String, int>;
//             ^^
// [cfe] Class 'N9' inherits multiple members named 'id' with incompatible signatures.
//             ^
// [cfe] The mixin application class 'N9' introduces an erroneous override of 'id'.
//                            ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class N10 extends NIIx with NBABxy<String, int> {}
//             ^^^
// [cfe] Applying the mixin 'NBABxy' to 'NIIx' introduces an erroneous override of 'id'.
//             ^
// [cfe] Class 'NIIx with NBABxy<String, int>' inherits multiple members named 'id' with incompatible signatures.
//                                   ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class N11 = NIIx with NTTy<int>;
//             ^^^
// [cfe] Class 'N11' inherits multiple members named 'id' with incompatible signatures.
//             ^
// [cfe] The mixin application class 'N11' introduces an erroneous override of 'id'.
//                             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class N12 extends NIIx with NTTy<int> {}
//             ^^^
// [cfe] Applying the mixin 'NTTy' to 'NIIx' introduces an erroneous override of 'id'.
//             ^
// [cfe] Class 'NIIx with NTTy<int>' inherits multiple members named 'id' with incompatible signatures.
//                                   ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class N13 = NIIx with NTTx<int>;
//             ^^^
// [cfe] Class 'N13' inherits multiple members named 'id' with incompatible signatures.
//             ^
// [cfe] The mixin application class 'N13' introduces an erroneous override of 'id'.
//                             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class N14 extends NIIx with NTTx<int> {}
//             ^^^
// [cfe] Applying the mixin 'NTTx' to 'NIIx' introduces an erroneous override of 'id'.
//             ^
// [cfe] Class 'NIIx with NTTx<int>' inherits multiple members named 'id' with incompatible signatures.
//                                   ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE

// Optional positional parameters
abstract class OII {
  int id([int x]) => x;
}

class OIII {
  int id([int x, int y]) => y;
}

class OIIy {
  int id([int y]) => y;
}

class PII {
  int id(int x) => x;
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

class OBAB<A, B> {
  B id ([A x, B y]) => y;
}

class OTTy<T> {
  T id([T y]) => y;
}

class PTT<T> {
  T id(T x) => x;
}

// Same as above but with generic classes.
abstract class O7 = OII with OBAB<int, int>;
abstract class O8 extends OII with OBAB<int, int> {}
abstract class O9 = OII with OBAB<String, int>;
//             ^^
// [cfe] Class 'O9' inherits multiple members named 'id' with incompatible signatures.
//             ^
// [cfe] The mixin application class 'O9' introduces an erroneous override of 'id'.
//                           ^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
abstract class O10 extends OII with OBAB<String, int> {}
//             ^^^
// [cfe] Applying the mixin 'OBAB' to 'OII' introduces an erroneous override of 'id'.
//             ^
// [cfe] Class 'OII with OBAB<String, int>' inherits multiple members named 'id' with incompatible signatures.
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

class MTTnum {
  T id<T extends num>(x) => x;
}

class MTTint {
  T id<T extends int>(x) => x;
}

class MTT {
  T id<T>(x) => x;
}

class MTTnumR {
  T id<T extends num, R>(x) => x;
}
class G1 = GTTnum with MTTnum;
class G2 = GTTnum with MTTint;
//    ^^
// [cfe] Class 'G2' inherits multiple members named 'id' with incompatible signatures.
//    ^
// [cfe] The mixin application class 'G2' introduces an erroneous override of 'id'.
//                     ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
class G3 = GTTnum with MTT;
//    ^^
// [cfe] Class 'G3' inherits multiple members named 'id' with incompatible signatures.
//    ^
// [cfe] The mixin application class 'G3' introduces an erroneous override of 'id'.
//                     ^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
class G4 = GTTnum with MTTnumR;
//    ^^
// [cfe] Class 'G4' inherits multiple members named 'id' with incompatible signatures.
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
