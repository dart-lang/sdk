// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Cake {
  final name;
  const Cake(this.name);

  @pragma("vm:external-name", "Cake_BakeMeACake")
  @JSName("Cake_BakeMeACake")
  // [error column 3, length 27]
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_ANNOTATION
  // [error column 4]
  // [cfe] Couldn't find constructor 'JSName'.
  external const factory Cake.BakeMeACake();
}

main() {
  var c = const Cake("Sacher");
}
