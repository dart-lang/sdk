// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N unnecessary_constructor_name`

class A {
  A.new(); // LINT
  A.ok(); // OK
}

var a = A.new(); // LINT
var aa = A(); // OK
var aaa = A.ok(); // OK
var makeA = A.new; // OK
