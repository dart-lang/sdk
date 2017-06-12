// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class ComparableMixin<E> {
  e() {
    return E;
  }
}

class KUID extends Object with ComparableMixin<KUID> {}

main() {
  var kuid = new KUID();
  Expect.equals(kuid.runtimeType.toString(), kuid.e().toString());
}
