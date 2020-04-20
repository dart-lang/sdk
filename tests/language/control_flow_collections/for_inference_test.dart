// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test how control flow interacts with inference.
import 'package:expect/expect.dart';

import 'utils.dart';

void main() {
  testBottomUpInference();
  testLoopVariableInference();
  testTopDownInference();
}

void testBottomUpInference() {
  // Lists.
  Expect.type<List<int>>([for (; false;) 1]);
  Expect.type<List<int>>([for (; false;) 1, for (; false;) 2]);
  Expect.type<List<num>>([for (; false;) 1, for (; false;) 0.2]);
  Expect.type<List<int>>([for (; false;) 1, 2]);
  Expect.type<List<num>>([for (; false;) 1, 0.2]);
  Expect.type<List<dynamic>>([for (; false;) ...[]]);
  Expect.type<List<int>>([for (; false;) ...<int>[]]);

  // Maps.
  Expect.type<Map<int, int>>({for (; false;) 1: 1});
  Expect.type<Map<int, int>>({for (; false;) 1: 1, for (; false;) 2: 2});
  Expect.type<Map<num, num>>({for (; false;) 1: 0.1, for (; false;) 0.2: 2});
  Expect.type<Map<int, int>>({for (; false;) 1: 1, 2: 2});
  Expect.type<Map<num, num>>({for (; false;) 1: 0.1, 0.2: 2});
  Expect.type<Map<dynamic, dynamic>>({for (; false;) ...{}});
  Expect.type<Map<int, int>>({for (; false;) ...<int, int>{}});

  // Sets.
  Expect.type<Set<int>>({for (; false;) 1});
  Expect.type<Set<int>>({for (; false;) 1, for (; false;) 2});
  Expect.type<Set<num>>({for (; false;) 1, for (; false;) 0.2});
  Expect.type<Set<int>>({for (; false;) 1, 2});
  Expect.type<Set<num>>({for (; false;) 1, 0.2});
  Expect.type<Set<dynamic>>({for (; false;) ...[]});
  Expect.type<Set<int>>({for (; false;) ...<int>[]});

  // If a nested iterable's type is dynamic, the element type is dynamic.
  Expect.type<List<dynamic>>([for (; false;) ...([] as dynamic)]);
  Expect.type<Set<dynamic>>({1, for (; false;) ...([] as dynamic)});

  // If a nested maps's type is dynamic, the key and value types are dynamic.
  Expect.type<Map<dynamic, dynamic>>({1: 1, for (; false;) ...({} as dynamic)});
}

void testLoopVariableInference() {
  // Infers loop variable from iterable.
  Expect.type<List<int>>([for (var i in <int>[1]) i]);
  Expect.type<List<String>>([for (var i in <int>[1]) i.toRadixString(10)]);

  // Infers loop variable from initializer.
  Expect.type<List<int>>([for (var i = 1; i < 2; i++) i]);
  Expect.type<List<String>>([for (var i = 1; i < 2; i++) i.toRadixString(10)]);

  // Loop variable type is pushed into sequence.
  Expect.listEquals(<int>[1], [for (int i in expectIntIterable([1])) i]);

  // Loop variable type is pushed into initializer.
  Expect.listEquals(<int>[1], [for (int i = expectInt(1); i < 2; i++) i]);
}

void testTopDownInference() {
  // Lists.

  // The context element type is pushed into the body.
  Expect.listEquals(<int>[1], <int>[for (var i = 0; i < 1; i++) expectInt(1)]);

  // Bottom up-inference from elements is not pushed back down into the body.
  Expect.listEquals(<int>[1, 2],
      [1, for (var i = 0; i < 1; i++) expectDynamic(2)]);

  // Maps.

  // The context element type is pushed into the body.
  Expect.mapEquals(<int, String>{1: "s"}, <int, String>{
    for (var i = 0; i < 1; i++) expectInt(1): expectString("s")
  });

  // Bottom up-inference from elements is not pushed back down into the body.
  Expect.mapEquals(<int, String>{1: "s", 2: "t"}, {
    1: "s",
    for (var i = 0; i < 1; i++) expectDynamic(2): expectDynamic("t")
  });

  // Sets.

  // The context element type is pushed into the body.
  Expect.setEquals(<int>{1}, <int>{for (var i = 0; i < 1; i++) expectInt(1)});

  // Bottom up-inference from elements is not pushed back down into the body.
  Expect.setEquals(<int>{1, 2},
      {1, for (var i = 0; i < 1; i++) expectDynamic(2)});
}
