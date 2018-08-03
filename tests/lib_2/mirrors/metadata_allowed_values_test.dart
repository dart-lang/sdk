// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.metadata_allowed_values;

import 'dart:mirrors';
import 'package:expect/expect.dart';

import 'metadata_allowed_values_import.dart'; // Unprefixed.
import 'metadata_allowed_values_import.dart' as prefix;

@A // //# 01: compile-time error
class A {}

@B.CONSTANT
class B {
  static const CONSTANT = 3;
}

@C(3)
class C {
  final field;
  const C(this.field);
}

@D.named(4)
class D {
  final field;
  const D.named(this.field);
}

@E.NOT_CONSTANT // //# 02: compile-time error
class E {
  static var NOT_CONSTANT = 3;
}

@F(6) // //# 03: compile-time error
class F {
  final field;
  F(this.field);
}

@G.named(4) // //# 04: compile-time error
class G {
  final field;
  G.named(this.field);
}

@H<int>() // //# 05: compile-time error
class H<T> {
  const H();
}

@I[0] // //# 06: compile-time error
class I {}

@this.toString // //# 07: compile-time error
class J {}

@super.toString // //# 08: compile-time error
class K {}

@L.func() // //# 09: compile-time error
class L {
  static func() => 6;
}

@Imported // //# 10: compile-time error
class M {}

@Imported()
class N {}

@Imported.named()
class O {}

@Imported.CONSTANT
class P {}

@prefix.Imported // //# 11: compile-time error
class Q {}

@prefix.Imported()
class R {}

@prefix.Imported.named()
class S {}

@prefix.Imported.CONSTANT
class T {}

@U..toString() // //# 12: compile-time error
class U {}

@V.tearOff // //# 13: compile-time error
class V {
  static tearOff() {}
}

topLevelTearOff() => 4;

@topLevelTearOff // //# 14: compile-time error
class W {}

@TypeParameter // //# 15: compile-time error
class X<TypeParameter> {}

@TypeParameter.member // //# 16: compile-time error
class Y<TypeParameter> {}

@1 // //# 17: compile-time error
class Z {}

@3.14 // //# 18: compile-time error
class AA {}

@'string' // //# 19: compile-time error
class BB {}

@#symbol // //# 20: compile-time error
class CC {}

@['element'] // //# 21: compile-time error
class DD {}

@{'key': 'value'} // //# 22: compile-time error
class EE {}

@true // //# 23: compile-time error
class FF {}

@false // //# 24: compile-time error
class GG {}

@null // //# 25: compile-time error
class HH {}

const a = const [1, 2, 3];

@a
class II {}

@a[0] // //# 26: compile-time error
class JJ {}

@kk // //# 27: compile-time error
class KK {
  const KK();
}

get kk => const KK();

@LL(() => 42) // //# 28: compile-time error
class LL {
  final field;
  const LL(this.field);
}

@MM((x) => 42) // //# 29: compile-time error
class MM {
  final field;
  const MM(this.field);
}

@NN(() {}) // //# 30: compile-time error
class NN {
  final field;
  const NN(this.field);
}

@OO(() { () {} }) // //# 31: compile-time error
class OO {
  final field;
  const OO(this.field);
}

checkMetadata(DeclarationMirror mirror, List expectedMetadata) {
  Expect.listEquals(expectedMetadata.map(reflect).toList(), mirror.metadata);
}

main() {
  reflectClass(A).metadata;
  checkMetadata(reflectClass(B), [B.CONSTANT]);
  checkMetadata(reflectClass(C), [const C(3)]);
  checkMetadata(reflectClass(D), [const D.named(4)]);
  reflectClass(E).metadata;
  reflectClass(F).metadata;
  reflectClass(G).metadata;
  reflectClass(H).metadata;
  reflectClass(I).metadata;
  reflectClass(J).metadata;
  reflectClass(K).metadata;
  reflectClass(L).metadata;
  reflectClass(M).metadata;
  checkMetadata(reflectClass(N), [const Imported()]);
  checkMetadata(reflectClass(O), [const Imported.named()]);
  checkMetadata(reflectClass(P), [Imported.CONSTANT]);
  reflectClass(Q).metadata;
  checkMetadata(reflectClass(R), [const prefix.Imported()]);
  checkMetadata(reflectClass(S), [const prefix.Imported.named()]);
  checkMetadata(reflectClass(T), [prefix.Imported.CONSTANT]);
  reflectClass(U).metadata;
  reflectClass(V).metadata;
  reflectClass(W).metadata;
  reflectClass(X).metadata;
  reflectClass(Y).metadata;
  reflectClass(Z).metadata;
  reflectClass(AA).metadata;
  reflectClass(BB).metadata;
  reflectClass(CC).metadata;
  reflectClass(DD).metadata;
  reflectClass(EE).metadata;
  reflectClass(FF).metadata;
  reflectClass(GG).metadata;
  reflectClass(HH).metadata;
  reflectClass(II).metadata;
  reflectClass(JJ).metadata;
  reflectClass(KK).metadata;
  reflectClass(LL).metadata;
  reflectClass(MM).metadata;
  reflectClass(NN).metadata;
  reflectClass(OO).metadata;
}
