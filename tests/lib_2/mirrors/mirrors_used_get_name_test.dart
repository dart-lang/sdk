// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to make sure that the names of classes that are marked with mirrors-used
// are preserved.
// In the test the class B is not instantiated, but we still want its names (the
// "foo") to be preserved.

@MirrorsUsed(targets: "B")
import 'dart:mirrors';
import 'package:expect/expect.dart';

class A {
  noSuchMethod(invocationMirror) {
    return MirrorSystem.getName(invocationMirror.memberName);
  }
}

class B {
  foo() => 499;
}

void main() {
  dynamic a = new A();
  if (new DateTime.now().year == 1984) {
    a = A;
  }
  Expect.equals("foo", a.foo());
}
