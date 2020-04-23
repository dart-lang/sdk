// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// Regression test for failure on CFE null-aware encoding.

// @dart=2.6

class Class {
  Map<String, Set<String>> map;

  List<String> method(String node, Set<String> set) => set.add(node)
      ? [node, ...?map[node]?.expand((node) => method(node, set))?.toList()]
      : [];
}

main(args) {
  if (false) new Class().method('', <String>{});
}
