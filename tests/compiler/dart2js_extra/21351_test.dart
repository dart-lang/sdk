// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  bool _flag = false;
  bool get flag => _flag;
}

main () {
  var value1, value2; 
  var count = 0;

  for (var x = 0; x < 10; x++) {
    var otherThing = new A();
    for (var dummy = 0; dummy < x; dummy++) {
      otherThing._flag = !otherThing._flag;
    }

    value1 = value2;
    value2 = otherThing;

    if (value1 == null) continue;

    if (value1.flag) count++;
  }

  if (count == 0) throw "FAIL";
}

