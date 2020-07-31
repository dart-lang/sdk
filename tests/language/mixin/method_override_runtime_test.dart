// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

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


// Wrong argument type.



// Similar as the above but using an instantiated class instead.
abstract class C5 = CII with CTT<int>;
abstract class C6 extends CII with CTT<int> {}



// Named parameters
abstract class NIIx {
  int? id({int? x}) => x;
}

class NIIxy {
  int? id({int? x, int? y}) => y;
}

class NIIy {
  int? id({int? y}) => y;
}

class NII {
  int? id(int? x) => x;
}

// It's OK to introduce more named parameters.
abstract class N1 = NIIx with NIIxy;
abstract class N2 extends NIIx with NIIxy {}
// It's NOT OK to rename named parameters.


// It's NOT OK to drop named parameters.



class NBABxy<A, B> {
  B? id ({A? x, B? y}) => y;
}

class NTTy<T> {
  T? id({T? y}) => y;
}

class NTTx<T> {
  T? id(T? x) => x;
}

// Same as above but with generic classes.
abstract class N7 = NIIx with NBABxy<int, int>;
abstract class N8 extends NIIx with NBABxy<int, int> {}







// Optional positional parameters
abstract class OII {
  int? id([int? x]) => x;
}

class OIII {
  int? id([int? x, int? y]) => y;
}

class OIIy {
  int? id([int? y]) => y;
}

class PII {
  int? id(int? x) => x;
}

// It's OK to introduce more optional parameters.
abstract class O1 = OII with OIII;
abstract class O2 extends OII with OIII {}
// It's OK to rename optional parameters.
abstract class O3 = OII with OIIy;
abstract class O4 extends OII with OIIy {}
// It's NOT OK to drop optional parameters.



class OBAB<A, B> {
  B? id ([A? x, B? y]) => y;
}

class OTTy<T> {
  T? id([T? y]) => y;
}

class PTT<T> {
  T? id(T? x) => x;
}

// Same as above but with generic classes.
abstract class O7 = OII with OBAB<int, int>;
abstract class O8 extends OII with OBAB<int, int> {}


abstract class O11 = OII with OTTy<int>;
abstract class O12 extends OII with OTTy<int> {}



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





void main() {}
