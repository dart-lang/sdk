// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  for (var _ in split([1,2,3])) {}
}

Iterable<(Iterable<A>, Iterable<A>)> split<A>(Iterable<A> it) => switch (it) {
  Iterable<A>(isEmpty: true) => [(Iterable<A>.empty(), Iterable<A>.empty())],
  Iterable<A>(first: var x) => () sync* {
    yield (Iterable<A>.empty(), it);
    for (var (ls, rs) in split(it.skip(1)))
      yield ([x, ...ls], rs);
    }(),
};
