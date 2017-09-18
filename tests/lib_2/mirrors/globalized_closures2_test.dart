// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart2js crashed on this example. It globalized both closures and created
// top-level classes for closures (here the globalized_closure{2}). There was a
// name-clash (both being named "main_closure") which led to a crash.

library main;

import 'dart:mirrors';

import 'package:expect/expect.dart';

confuse(x) {
  if (new DateTime.now().millisecondsSinceEpoch == 42) {
    return confuse(() => print(42));
  }
  return x;
}

main() {
  var globalized_closure = confuse(() => 499);
  var globalized_closure2 = confuse(() => 99);
  globalized_closure();
  globalized_closure2();
  final ms = currentMirrorSystem();
  var lib = ms.findLibrary(#main);
  var collectedParents = [];
  var classes = lib.declarations.values;
  for (var c in classes) {
    if (c is ClassMirror && c.superclass != null) {
      collectedParents.add(MirrorSystem.getName(c.superclass.simpleName));
    }
  }
  ;
  Expect.isTrue(collectedParents.isEmpty); //  //# 00: ok
}
