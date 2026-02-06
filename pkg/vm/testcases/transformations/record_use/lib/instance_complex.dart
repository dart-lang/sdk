// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart' show RecordUse;

void main() {
  print(
    const MyClass(
      i: 15,
      s: 's',
      b: true,
      l: [
        {'l': 3},
      ],
      m: {'h': false},
      n: null,
    ),
  );
}

@RecordUse()
class MyClass {
  final int i;
  final String s;
  final Map<String, bool> m;
  final bool b;
  final List<Map<String, int>> l;
  final String? n;

  const MyClass({
    required this.i,
    required this.s,
    required this.m,
    required this.b,
    required this.l,
    required this.n,
  });
}
