// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.typevariable_metadata_test;

import "dart:mirrors";

import "metadata_test.dart";

const m1 = 'm1';
const m2 = const Symbol('m2');
const m3 = 3;

class A <S, @m1 @m2 T> {
  // TODO(13327): Remove this once the name collision is prohibited by the
  // compiler/runtime.
  @m3
  T() => null;
}

class B <@m3 T> {
  // TODO(13327): Remove this once the name collision is prohibited by the
  // compiler/runtime.
  @m1
  @m2
  var T;
}

typedef bool Predicate<@m1 @m2 G>(G a);

main() {
  ClassMirror cm;
  cm = reflectClass(A);
  checkMetadata(cm.typeVariables[const Symbol('S')], []);
  checkMetadata(cm.typeVariables[const Symbol('T')], [m1, m2]);
  // Check for conflicts.
  checkMetadata(cm.methods[const Symbol('T')], [m3]);

  cm = reflectClass(B);
  checkMetadata(cm.typeVariables[const Symbol('T')], [m3]);
  // Check for conflicts.
  checkMetadata(cm.members[const Symbol('T')], [m1, m2]);

  TypedefMirror tm = reflectClass(Predicate);
  FunctionTypeMirror ftm = tm.referent;
  checkMetadata(ftm.typeVariables[const Symbol('G')], [m1, m2]);
}
