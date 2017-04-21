// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/19173

import 'dart:mirrors';

class A {
  const A();
}

@deprecated
const A anA = const A();

main() {
  ClassMirror typeMirror = reflectType(A);
  var decs = typeMirror.declarations;
  print(decs.length);
}
