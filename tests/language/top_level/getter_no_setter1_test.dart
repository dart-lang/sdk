// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

bool getter_visited = false;

int get getter {
  getter_visited = true;
  return -1;
}

class Class {
  method() {
      getter++; /*@compile-error=unspecified*/
  }
}

main() {
  new Class().method();
}
