// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class X {}

checkme<T extends X>(T? t) {}
typedef Test<T extends X>(T? t);

main() {
  Test<X> t2 = checkme;
}
