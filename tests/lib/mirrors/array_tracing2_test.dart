// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;

@MirrorsUsed(targets: const ["lib", "dart.core"])
import 'dart:mirrors';

class A {
  var field;
}

main() {
  var a = new A();
  var mirror = reflect(a);
  var array = [42];
  a.field = array;
  var field = mirror.getField(#field);
  field.invoke(#clear, []);
  if (array.length == 1) throw 'Test failed';
}
