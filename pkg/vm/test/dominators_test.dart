// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:vm/dominators.dart';

class StringVertex extends Vertex<StringVertex> {
  final String name;
  StringVertex(this.name);
  String toString() => name;
}

main() {
  // small example from [Lenguaer & Tarjan 1979]
  var R = new StringVertex("R");
  var A = new StringVertex("A");
  var B = new StringVertex("B");
  var C = new StringVertex("C");
  var D = new StringVertex("D");
  var E = new StringVertex("E");
  var F = new StringVertex("F");
  var G = new StringVertex("G");
  var H = new StringVertex("H");
  var I = new StringVertex("I");
  var J = new StringVertex("J");
  var K = new StringVertex("K");
  var L = new StringVertex("L");

  R.successors.add(A);
  R.successors.add(B);
  R.successors.add(C);
  A.successors.add(D);
  B.successors.add(A);
  B.successors.add(D);
  B.successors.add(E);
  C.successors.add(F);
  C.successors.add(G);
  D.successors.add(L);
  E.successors.add(H);
  F.successors.add(I);
  G.successors.add(I);
  G.successors.add(J);
  H.successors.add(E);
  H.successors.add(K);
  I.successors.add(K);
  J.successors.add(I);
  K.successors.add(I);
  K.successors.add(R);
  L.successors.add(H);

  computeDominators(R);

  for (var x in [R, A, B, C, D, E, F, G, H, I, J, K, L]) {
    print("dom($x) = ${x.dominator}");
  }

  Expect.equals(null, R.dominator);

  Expect.equals(R, I.dominator);
  Expect.equals(R, K.dominator);
  Expect.equals(R, C.dominator);
  Expect.equals(R, H.dominator);
  Expect.equals(R, E.dominator);
  Expect.equals(R, A.dominator);
  Expect.equals(R, D.dominator);
  Expect.equals(R, B.dominator);

  Expect.equals(C, F.dominator);
  Expect.equals(C, G.dominator);

  Expect.equals(G, J.dominator);

  Expect.equals(D, L.dominator);
}
