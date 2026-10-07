// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  const C();
}

int? nullableKey() => 1;

class Holder {
  late final fieldMap = <int, C>{
    ?nullableKey(): const C(),
  };
}

void main() {
  final map = <int, C>{
    ?nullableKey(): const C(),
  };
  print(map);
  print(Holder().fieldMap);
}
