// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library foo;

import 'dart:mirrors';
import 'typedef_library.dart';

import 'package:expect/expect.dart';

main() {
  var barLibrary = currentMirrorSystem().findLibrary(new Symbol("bar"));
  var gTypedef = barLibrary.declarations[new Symbol("G")]!;
  Expect.equals("G", MirrorSystem.getName(gTypedef.simpleName));
}
