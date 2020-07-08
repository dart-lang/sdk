// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// 'dart:mirrors' provides no functionality in dart-web, but can be imported and
// all APIs throw.
import 'dart:mirrors';
import 'package:expect/expect.dart';

main() {
  Expect.throws<UnsupportedError>(() => currentMirrorSystem());
  Expect.throws<UnsupportedError>(() => reflect(main));
  Expect.throws<UnsupportedError>(() => reflectClass(Object));
  Expect.throws<UnsupportedError>(() => reflectType(Object));
  Expect.throws<UnsupportedError>(() => MirrorSystem.getName(#core));
  Expect.throws<UnsupportedError>(() => MirrorSystem.getSymbol("core"));
}
