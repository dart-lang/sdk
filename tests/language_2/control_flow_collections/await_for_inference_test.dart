// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test how await for interacts with inference.
import "package:async_helper/async_helper.dart";
import 'package:expect/expect.dart';

import 'utils.dart';

Stream<int> stream() => Stream.fromIterable([1]);

void main() {
  asyncTest(() async {
    await testBottomUpInference();
    await testLoopVariableInference();
    await testTopDownInference();
  });
}

Future<void> testBottomUpInference() async {
  // Lists.
  Expect.type<List<int>>([await for (var i in stream()) 1]);
  Expect.type<List<int>>(
      [await for (var i in stream()) 1, await for (var i in stream()) 2]);
  Expect.type<List<num>>(
      [await for (var i in stream()) 1, await for (var i in stream()) 0.2]);
  Expect.type<List<int>>([await for (var i in stream()) 1, 2]);
  Expect.type<List<num>>([await for (var i in stream()) 1, 0.2]);
  Expect.type<List<dynamic>>([await for (var i in stream()) ...[]]);
  Expect.type<List<int>>([await for (var i in stream()) ...<int>[]]);

  // Maps.
  Expect.type<Map<int, int>>({await for (var i in stream()) 1: 1});
  Expect.type<Map<int, int>>(
      {await for (var i in stream()) 1: 1, await for (var i in stream()) 2: 2});
  Expect.type<Map<num, num>>({
    await for (var i in stream()) 1: 0.1,
    await for (var i in stream()) 0.2: 2
  });
  Expect.type<Map<int, int>>({await for (var i in stream()) 1: 1, 2: 2});
  Expect.type<Map<num, num>>({await for (var i in stream()) 1: 0.1, 0.2: 2});
  Expect.type<Map<dynamic, dynamic>>({await for (var i in stream()) ...{}});
  Expect.type<Map<int, int>>({await for (var i in stream()) ...<int, int>{}});

  // Sets.
  Expect.type<Set<int>>({await for (var i in stream()) 1});
  Expect.type<Set<int>>(
      {await for (var i in stream()) 1, await for (var i in stream()) 2});
  Expect.type<Set<num>>(
      {await for (var i in stream()) 1, await for (var i in stream()) 0.2});
  Expect.type<Set<int>>({await for (var i in stream()) 1, 2});
  Expect.type<Set<num>>({await for (var i in stream()) 1, 0.2});
  Expect.type<Set<dynamic>>({await for (var i in stream()) ...[]});
  Expect.type<Set<int>>({await for (var i in stream()) ...<int>[]});

  // If a nested iterable's type is dynamic, the element type is dynamic.
  Expect.type<List<dynamic>>(
      [1, await for (var i in stream()) ...([] as dynamic)]);
  Expect.type<Set<dynamic>>(
      {1, await for (var i in stream()) ...([] as dynamic)});

  // If a nested maps's type is dynamic, the key and value types are dynamic.
  Expect.type<Map<dynamic, dynamic>>(
      {1: 1, await for (var i in stream()) ...({} as dynamic)});
}

Future<void> testLoopVariableInference() async {
  // Infers loop variable from stream.
  Expect.type<List<int>>([await for (var i in stream()) i]);
  Expect.type<List<String>>(
      [await for (var i in stream()) i.toRadixString(10)]);

  // Loop variable type is pushed into stream.
  Expect.listEquals(<int>[1], [await for (int i in expectIntStream([1])) i]);
}

Future<void> testTopDownInference() async {
  // Lists.

  // The context element type is pushed into the body.
  Expect.listEquals(<int>[1],
      <int>[await for (var i in stream()) expectInt(1)]);

  // Bottom up-inference from elements is not pushed back down into the body.
  Expect.listEquals(<int>[1, 2],
      [1, await for (var i in stream()) expectDynamic(2)]);

  // Maps.

  // The context element type is pushed into the body.
  Expect.mapEquals(<int, String>{1: "s"}, <int, String>{
    await for (var i in stream()) expectInt(1): expectString("s")
  });

  // Bottom up-inference from elements is not pushed back down into the body.
  Expect.mapEquals(<int, String>{1: "s", 2: "t"}, {
    1: "s",
    await for (var i in stream()) expectDynamic(2): expectDynamic("t")
  });

  // Sets.

  // The context element type is pushed into the body.
  Expect.setEquals(<int>{1}, <int>{await for (var i in stream()) expectInt(1)});

  // Bottom up-inference from elements is not pushed back down into the body.
  Expect.setEquals(<int>{1, 2},
      {1, await for (var i in stream()) expectDynamic(2)});
}
