// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

class Cake {
  final name;
  const Cake(this.name);

  @pragma("vm:external-name", "Cake_BakeMeACake")
  @JSName("Cake_BakeMeACake")
  external const factory Cake.BakeMeACake(); /*@compile-error=unspecified*/
}

main() {
  var c = const Cake("Sacher");
}
