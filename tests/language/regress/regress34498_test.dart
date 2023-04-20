// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:core' as core;

class A {
  core.List get core => throw "uncalled";
//^^^^
// [analyzer] COMPILE_TIME_ERROR.PREFIX_SHADOWED_BY_LOCAL_DECLARATION
// [cfe] 'core.List' can't be used as a type because 'core' doesn't refer to an import prefix.
}

main() {
  new A().core;
}
