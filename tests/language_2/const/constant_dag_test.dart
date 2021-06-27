// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

// Test the efficient processing of constants that are DAGs.
//
// This test requires processing a constant that is a DAG of N nodes (N=40). If
// the DAG is traversed as a tree, it will require exponential node visits and
// take time O(2^N) i.e. 2^40, and the test will time out.

main() {
  Expect.equals(40, n40.lengthA);
  Expect.equals(40, n40.lengthB);
}

class Node {
  final Node a;
  final Node b;
  const Node(this.a, this.b);

  int get lengthA => a == null ? 0 : 1 + a.lengthA;
  int get lengthB => b == null ? 0 : 1 + b.lengthB;
}

const n0 = Node(null, null);
const n1 = Node(n0, n0);
const n2 = Node(n1, n1);
const n3 = Node(n2, n2);
const n4 = Node(n3, n3);
const n5 = Node(n4, n4);
const n6 = Node(n5, n5);
const n7 = Node(n6, n6);
const n8 = Node(n7, n7);
const n9 = Node(n8, n8);
const n10 = Node(n9, n9);
const n11 = Node(n10, n10);
const n12 = Node(n11, n11);
const n13 = Node(n12, n12);
const n14 = Node(n13, n13);
const n15 = Node(n14, n14);
const n16 = Node(n15, n15);
const n17 = Node(n16, n16);
const n18 = Node(n17, n17);
const n19 = Node(n18, n18);
const n20 = Node(n19, n19);
const n21 = Node(n20, n20);
const n22 = Node(n21, n21);
const n23 = Node(n22, n22);
const n24 = Node(n23, n23);
const n25 = Node(n24, n24);
const n26 = Node(n25, n25);
const n27 = Node(n26, n26);
const n28 = Node(n27, n27);
const n29 = Node(n28, n28);
const n30 = Node(n29, n29);
const n31 = Node(n30, n30);
const n32 = Node(n31, n31);
const n33 = Node(n32, n32);
const n34 = Node(n33, n33);
const n35 = Node(n34, n34);
const n36 = Node(n35, n35);
const n37 = Node(n36, n36);
const n38 = Node(n37, n37);
const n39 = Node(n38, n38);
const n40 = Node(n39, n39);
