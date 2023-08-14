// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'libraries_lib1.lib.dart';
import 'libraries_lib2.lib.dart';
import 'libraries_lib3.lib.dart';

void unused() {
  print(Foo1());
  print(bar1());
}

void used() {
  print(Foo2());
  print(bar2());
  print(privateSymbol);
}

main() {
  used();
}
