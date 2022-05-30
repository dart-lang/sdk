// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  print(main is Function());
  print((<T>(T x) => x).runtimeType);
  print((<T extends num>(T x) => x).runtimeType);
  print((<T extends Comparable<T>>(T x) => x).runtimeType);
  print((<T extends Comparable<S>, S>(T x) => x).runtimeType);
  print((<T extends Function(T)>(T x) => x).runtimeType);
  print((<T extends List<List<T>>>(T x) => x).runtimeType);
}
