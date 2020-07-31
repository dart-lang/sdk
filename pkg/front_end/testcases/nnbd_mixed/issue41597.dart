// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'issue41597_lib.dart';

bool x;
bool x;

errors() {
  print(x);
  print(x!);
  print(!x);
}

class C {
  C.c0() : super();
  C.c1() : super()!;
}

main() {}
