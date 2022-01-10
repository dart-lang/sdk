// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--no-use-vfp

import 'dart:typed_data';

import 'package:expect/expect.dart';

final Float32List l = int.parse('1') == 1
    ? Float32List(2)
    : Float32List.view(Uint32List(2).buffer);

main() {
  l[int.parse('1') == 1 ? 0 : 1] = 1.2;
  Expect.approxEquals(l[0], 1.2);
}
