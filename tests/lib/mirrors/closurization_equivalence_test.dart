// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;

@MirrorsUsed(targets: "lib")
import 'dart:mirrors';
import 'package:expect/expect.dart';

topLevelMethod() {}

class C {
  static staticMethod() {}
  instanceMethod() {}
}

main() {
  LibraryMirror thisLibrary = reflectClass(C).owner;
  Expect.equals(thisLibrary.declarations[#topLevelMethod],
      (reflect(topLevelMethod) as ClosureMirror).function, "topLevel");

  Expect.equals(reflectClass(C).declarations[#staticMethod],
      (reflect(C.staticMethod) as ClosureMirror).function, "static");

  Expect.equals(reflectClass(C).declarations[#instanceMethod],
      (reflect(new C().instanceMethod) as ClosureMirror).function, "instance");
}
