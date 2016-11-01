// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class SuperClass {
  final field = 0;
  noSuchMethod(_) => 42;
}

class Class extends SuperClass {
  m() {
    super.field = 87; /// 01: static type warning
  }
}

main() {
  new Class().m(); /// 01: continued
}