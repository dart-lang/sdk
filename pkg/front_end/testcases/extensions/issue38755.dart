// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final list = ["a", "b", "c"].myMap((it) => it);

extension A<T> on List<T> {
  List<R> myMap<R>(R Function(T) block) {
    return map(block).toList();
  }
}

main() {
  print(list);
}
