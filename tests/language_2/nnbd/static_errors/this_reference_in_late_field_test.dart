// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "package:expect/expect.dart";

// SharedOptions=--enable-experiment=non-nullable
void main() {
  final c = C();
  Expect.identical(c, c);
}

class C {
  var x = this; //# 00: compile-time error
  late var x = this; //# 01: ok
}
