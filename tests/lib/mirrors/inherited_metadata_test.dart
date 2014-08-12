// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.mirrors;

@MirrorsUsed(targets: "test.mirrors")
import 'dart:mirrors';

import 'package:expect/expect.dart';


class RemoteClass {
  final String name;
  const RemoteClass([this.name]);
}

class A {
}

@RemoteClass("ASF")
class B extends A {
}

class C extends B {
}


void main() {
  bool foundB = false;

  MirrorSystem mirrorSystem = currentMirrorSystem();
  mirrorSystem.libraries.forEach((lk, l) {
    l.declarations.forEach((dk, d) {
      if(d is ClassMirror) {
        d.metadata.forEach((md) {
          InstanceMirror metadata = md as InstanceMirror;
          // Metadata must not be inherited.
          if(metadata.type == reflectClass(RemoteClass)) {
            Expect.isFalse(foundB);
            Expect.equals(#B, d.simpleName);
            foundB = true;
          }
        });
      }
    });
  });

  Expect.isTrue(foundB);
}

