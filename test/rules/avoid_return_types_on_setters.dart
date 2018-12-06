// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_return_types_on_setters`

set speed(int ms) {} //OK
void set speed2(int ms) {} //LINT

class Car {
  static set make(String name) {} // OK
  static void set model(String name) {} //LINT

  set speed(int ms) {} //OK
  void set speed2(int ms) {} //LINT
}
