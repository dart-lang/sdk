// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// @dart = 2.7

// Regression test for failure on CFE null-aware encoding.

class Class {
  Map<String, Set<String>> map;

  List<String> method(String node, Set<String> set) =>
      set.add(node)
          ? [
              node,
              ...?map[node]
                  ?.expand((node) => method(node, set))
                  ?.toList()
            ]
          : [];
}

main(args) {
  if (args != null && args.isNotEmpty) new Class().method('', <String>{});
}
