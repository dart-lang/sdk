// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2wasm/deferred_load/dominators.dart';
import 'package:expect/expect.dart';

void main() {
  // Tree structure:
  //      A
  //     / \
  //    B   C
  //   / \
  //  D   E
  //      |
  //      F

  final a = DominatorNode<String>('A', null);
  final b = DominatorNode<String>('B', a);
  final c = DominatorNode<String>('C', a);
  final d = DominatorNode<String>('D', b);
  final e = DominatorNode<String>('E', b);
  final f = DominatorNode<String>('F', e);

  // Test structure
  Expect.equals(null, a.dominator);
  Expect.equals(a, b.dominator);
  Expect.equals(a, c.dominator);
  Expect.equals(b, d.dominator);
  Expect.equals(b, e.dominator);
  Expect.equals(e, f.dominator);

  Expect.listEquals([b, c], a.children);
  Expect.listEquals([d, e], b.children);
  Expect.listEquals([], c.children);
  Expect.listEquals([], d.children);
  Expect.listEquals([f], e.children);
  Expect.listEquals([], f.children);

  // Test depth
  Expect.equals(0, a.depth);
  Expect.equals(1, b.depth);
  Expect.equals(1, c.depth);
  Expect.equals(2, d.depth);
  Expect.equals(2, e.depth);
  Expect.equals(3, f.depth);

  // Test visitDFS
  final preOrder = <String>[];
  final postOrder = <String>[];
  a.visitDFS((node) => preOrder.add(node.prefix),
      (node) => postOrder.add(node.prefix));
  Expect.listEquals(['A', 'B', 'D', 'E', 'F', 'C'], preOrder);
  Expect.listEquals(['D', 'F', 'E', 'B', 'C', 'A'], postOrder);

  // Test commonDominator
  Expect.equals(a, a.commonDominator(a));
  Expect.equals(a, a.commonDominator(b));
  Expect.equals(a, b.commonDominator(c));
  Expect.equals(b, d.commonDominator(e));
  Expect.equals(b, d.commonDominator(f));
  Expect.equals(a, d.commonDominator(c));
  Expect.equals(e, e.commonDominator(f));

  // Test strictlyDominates
  Expect.isFalse(a.strictlyDominates(a));
  Expect.isTrue(a.strictlyDominates(b));
  Expect.isTrue(a.strictlyDominates(f));
  Expect.isTrue(b.strictlyDominates(d));
  Expect.isTrue(b.strictlyDominates(f));
  Expect.isFalse(b.strictlyDominates(c));
  Expect.isFalse(d.strictlyDominates(e));
  Expect.isFalse(f.strictlyDominates(a));

  // Test dominates
  Expect.isTrue(a.dominates(a));
  Expect.isTrue(a.dominates(b));
  Expect.isTrue(a.dominates(f));
  Expect.isTrue(b.dominates(d));
  Expect.isTrue(b.dominates(f));
  Expect.isFalse(b.dominates(c));
  Expect.isFalse(d.dominates(e));
  Expect.isFalse(f.dominates(a));
}
