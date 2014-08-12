// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library subclass;

import 'interesting.dart';

import 'private.dart' as p;

class S extends p.P {
  superMethod1() {
  }
  superMethod2() {
  }
  static staticSuperMethod1() {
  }
  static staticSuperMethod2() {
  }
}

class C extends S {
  instanceMethod1() {
  }
  instanceMethod2() {
  }
  static staticMethod1() {
  }
  static staticMethod2() {
  }
}

main() {}
