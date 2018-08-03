// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart2js crashed on this example. It globalized closures and created
// top-level classes for closures (here the globalized_closure). There was a
// name-clash with the global "main_closure" class which led to a crash.

library main;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class main_closure {}

confuse(x) {
  if (new DateTime.now().millisecondsSinceEpoch == 42) return confuse(() => 42);
  return x;
}

main() {
  new main_closure();
  var globalized_closure = confuse(() => 499);
  globalized_closure();
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
  Expect.listEquals(["Object"], collectedParents); //  //# 00: ok
}
