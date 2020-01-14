// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we report a compile-time error when a type parameter conflicts
// with an instance or static member with the same name.

import "package:expect/expect.dart";

class G1<T> {

}

class G2<T> {

}

class G3<T> {

}

class G4<T> {

}

class G5<T> {

}

class G6<T> {

}

class G7<T> {

}

class G8<T> {

}

main() {
  new G1<int>();
  new G2<int>();
  new G3<int>();
  new G4<int>();
  new G5<int>();
  new G6<int>();
  new G7<int>();
  new G8<int>();
}
