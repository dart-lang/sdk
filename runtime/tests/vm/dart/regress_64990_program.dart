// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Program used by regress_64990_test.dart.
//
// The canonical closure for the tear-off of `wrap` remains in the weakened
// constants table of the closure class, but is not otherwise reachable when
// the snapshot is written.

extension Let<T extends Object> on T {
  R let<R>(R Function(T it) block) => block(this);
}

Object? wrap(Object? value) => value;

class Comparator<T extends Object> {
  Comparator(this.getter);
  final Object? Function(T) getter;

  int call(T a) => a.let(getter)?.let(wrap) == null ? 0 : 1;

  Holder toHolder() => Holder(call);
}

class Holder {
  Holder(this.compare);
  final Function compare;
}

final a = Comparator<String>((it) => it.length).toHolder();
final b = Comparator<String>((it) => it.isEmpty).toHolder();

void main() {
  print(a);
  print(b);
}
