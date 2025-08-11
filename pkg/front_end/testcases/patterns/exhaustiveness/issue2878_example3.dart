// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  List<int> list = [1, 2, 3];
  print(subs(list));
}

List<List<A>> subs<A>(List<A> list) => switch (list) {
      [] => [],
      [var x, ...var xs] => [
        for (var ys in subs(xs)) ...[
          [x] + ys,
          ys
        ],
        [x]
      ],
    };
