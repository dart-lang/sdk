// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

@MirrorsUsed(override: '*')
import 'dart:mirrors';

import 'deferred_mirrors2_lib2.dart';

foo() {
  ClassMirror classMirror = reflectType(int);
  Expect.isTrue(classMirror.isTopLevel);
}

// This is a minimal test extracted from a bug-report we got.
main() {
  foo();
}
