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
abstract class C1 = CII with CIS; //# C1: compile-time error
abstract class C2 extends CII with CIS {} //# C2: compile-time error
// Wrong argument type.
abstract class C3 = CII with CSI; //# C3: compile-time error
abstract class C4 extends CII with CSI {} //# C4: compile-time error

// Similar as the above but using an instantiated class instead.
abstract class C5 = CII with CTT<int>;
abstract class C6 extends CII with CTT<int> {}
abstract class C7  = CII with CTT<String>; //# C7: compile-time error
abstract class C8 extends CII with CTT<String> {} //# C8: compile-time error

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
abstract class N3 = NIIx with NIIy; //# N3: compile-time error
abstract class N4 extends NIIx with NIIy {} //# N4: compile-time error
// It's NOT OK to drop named parameters.
abstract class N5 = NIIx with NII; //# N5: compile-time error
abstract class N6 extends NIIx with NII {} //# N6: compile-time error

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
abstract class N9 = NIIx with NBABxy<String, int>; //# N9: compile-time error
abstract class N10 extends NIIx with NBABxy<String, int> {} //# N10: compile-time error
abstract class N11 = NIIx with NTTy<int>; //# N11: compile-time error
abstract class N12 extends NIIx with NTTy<int> {} //# N12: compile-time error
abstract class N13 = NIIx with NTTx<int>; //# N13: compile-time error
abstract class N14 extends NIIx with NTTx<int> {} //# N14: compile-time error

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
abstract class O5 = OII with PII; //# O5: compile-time error
abstract class O6 extends OII with PII {} //# O6: compile-time error

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
abstract class O9 = OII with OBAB<String, int>; //# O9: compile-time error
abstract class O10 extends OII with OBAB<String, int> {} //# O10: compile-time error
abstract class O11 = OII with OTTy<int>;
abstract class O12 extends OII with OTTy<int> {}
abstract class O13 = OII with PTT<int>; //# O13: compile-time error
abstract class O14 extends OII with PTT<int> {} //# O14: compile-time error

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
class G2 = GTTnum with MTTint; //# G2: compile-time error
class G3 = GTTnum with MTT; //# G3: compile-time error
class G4 = GTTnum with MTTnumR; //# G4: compile-time error
class G5 = GTTnum with CII; //# G5: compile-time error

void main() {}
