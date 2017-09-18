// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Cake {
  final name;
  const Cake(this.name);
  const factory BakeMeACake()
      native "Cake_BakeMeACake";    /*@compile-error=unspecified*/
}

main() {
  var c = const Cake("Sacher");
}
