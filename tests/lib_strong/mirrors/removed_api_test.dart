// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'package:expect/expect.dart';

class C {}

expectThrowsNSM(f) {
  Expect.throws(f, (e) => e is NoSuchMethodError);
}

main() {
  expectThrowsNSM(() => reflectClass(C).newInstanceAsync(const Symbol(''), []));
  expectThrowsNSM(() => reflect(() => 3).applyAsync([]));

  expectThrowsNSM(() => reflectClass(C).owner.members);
  expectThrowsNSM(() => reflectClass(C).owner.classes);
  expectThrowsNSM(() => reflectClass(C).owner.types);
  expectThrowsNSM(() => reflectClass(C).owner.functions);
  expectThrowsNSM(() => reflectClass(C).owners.getters);
  expectThrowsNSM(() => reflectClass(C).owners.setters);
  expectThrowsNSM(() => reflectClass(C).owners.variables);

  expectThrowsNSM(() => reflectClass(C).members);
  expectThrowsNSM(() => reflectClass(C).methods);
  expectThrowsNSM(() => reflectClass(C).getters);
  expectThrowsNSM(() => reflectClass(C).setters);
  expectThrowsNSM(() => reflectClass(C).variables);
  expectThrowsNSM(() => reflectClass(C).constructors);

  expectThrowsNSM(() => MirroredError);
  expectThrowsNSM(() => MirrorException);
  expectThrowsNSM(() => MirroredUncaughtExceptionError);
  expectThrowsNSM(() => MirroredCompilationError);
}
