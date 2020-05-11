// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test how control flow interacts with inference.
import 'package:expect/expect.dart';

import 'utils.dart';

void main() {
  testBottomUpInference();
  testTopDownInference();
}

void testBottomUpInference() {
  // Lists.
  expectListOf<int>([if (true) 1]);
  expectListOf<int>([if (true) 1 else 2]);
  expectListOf<num>([if (true) 1 else 0.2]);
  expectListOf<int>([if (true) 1, 2]);
  expectListOf<num>([if (true) 1, 0.2]);
  expectListOf<dynamic>([if (true) ...[]]);
  expectListOf<int>([if (true) ...<int>[]]);

  // Maps.
  expectMapOf<int, int>({if (true) 1: 1});
  expectMapOf<int, int>({if (true) 1: 1 else 2: 2});
  expectMapOf<num, num>({if (true) 1: 0.1 else 0.2: 2});
  expectMapOf<int, int>({if (true) 1: 1, 2: 2});
  expectMapOf<num, num>({if (true) 1: 0.1, 0.2: 2});
  expectMapOf<dynamic, dynamic>({if (true) ...{}});
  expectMapOf<int, int>({if (true) ...<int, int>{}});

  // Sets.
  expectSetOf<int>({if (true) 1});
  expectSetOf<int>({if (true) 1 else 2});
  expectSetOf<num>({if (true) 1 else 0.2});
  expectSetOf<int>({if (true) 1, 2});
  expectSetOf<num>({if (true) 1, 0.2});
  expectSetOf<dynamic>({if (true) ...[]});
  expectSetOf<int>({if (true) ...<int>[]});

  // If a nested iterable's type is dynamic, the element type is dynamic.
  expectListOf<dynamic>([if (true) ...([] as dynamic)]);
  expectSetOf<dynamic>({1, if (true) ...([] as dynamic)});

  // If a nested maps's type is dynamic, the key and value types are dynamic.
  expectMapOf<dynamic, dynamic>({1: 1, if (true) ...({} as dynamic)});
}

void testTopDownInference() {
  // Lists.

  // The context element type is pushed into the branches.
  Expect.listEquals(<int>[1], <int>[if (true) expectInt(1)]);
  Expect.listEquals(<int>[1], <int>[if (false) 9 else expectInt(1)]);

  // Bottom up-inference from elements is not pushed back down into branches.
  Expect.listEquals(<int>[1, 2], [1, if (true) expectDynamic(2)]);
  Expect.listEquals(<int>[1, 2], [1, if (false) 9 else expectDynamic(2)]);

  // Maps.

  // The context element type is pushed into the branches.
  Expect.mapEquals(<int, String>{1: "s"},
      <int, String>{if (true) expectInt(1): expectString("s")});

  // Bottom up-inference from elements is not pushed back down into branches.
  Expect.mapEquals(<int, String>{1: "s", 2: "t"},
      {1: "s", if (true) expectDynamic(2): expectDynamic("t")});

  // Sets.

  // The context element type is pushed into the branches.
  Expect.setEquals(<int>{1}, <int>{if (true) expectInt(1)});
  Expect.setEquals(<int>{1}, <int>{if (false) 9 else expectInt(1)});

  // Bottom up-inference from elements is not pushed back down into branches.
  Expect.setEquals(<int>{1, 2}, {1, if (true) expectDynamic(2)});
  Expect.setEquals(<int>{1, 2}, {1, if (false) 9 else expectDynamic(2)});
}
