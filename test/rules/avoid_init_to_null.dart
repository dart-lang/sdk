// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test/util/solo_test.dart avoid_init_to_null`

var x = null; //LINT
var y; //OK
var z = 1; //OK

class X {
  int x = null; //LINT
  int y; //OK
}
