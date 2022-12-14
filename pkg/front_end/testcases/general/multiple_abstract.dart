// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface1 {
  void method();
}

abstract class Interface2 {
  void method();
}

class Class implements Interface1, Interface2 {}
