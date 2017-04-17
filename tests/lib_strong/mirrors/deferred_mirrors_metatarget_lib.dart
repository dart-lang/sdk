// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;

@MirrorsUsed(metaTargets: "MetaTarget")
import "dart:mirrors";

class MetaTarget {
  const MetaTarget();
}

@MetaTarget()
class A {
  String toString() => "A";
}

String foo() {
  ClassMirror a = currentMirrorSystem().findLibrary(#lib).declarations[#A];
  return a.newInstance(const Symbol(""), []).invoke(#toString, []).reflectee;
}
