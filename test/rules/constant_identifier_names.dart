// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N constant_identifier_names`

const DEFAULT_TIMEOUT = 1000; //LINT
const PI = 3.14; //LINT

class Z {
  static const DEBUG = false; //LINT
}

enum Foo {
  bar,
  Baz, //LINT
}
