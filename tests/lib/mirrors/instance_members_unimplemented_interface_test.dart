// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.instance_members_unimplemented_interface;

@MirrorsUsed(targets: "test.instance_members_unimplemented_interface")
import 'dart:mirrors';
import 'package:expect/expect.dart';

class I {
  implementMe() {}
}

abstract class C implements I {}

selectKeys(map, predicate) {
  return map.keys.where((key) => predicate(map[key]));
}

main() {
  ClassMirror cm = reflectClass(C);

  // N.B.: Does not include #implementMe.
  Expect.setEquals([#hashCode, #runtimeType, #==, #noSuchMethod, #toString],
      selectKeys(cm.instanceMembers, (dm) => !dm.isPrivate));
  // Filter out private to avoid implementation-specific members of Object.
}
