// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MyClass {
  int fieldName;

  MyClass(this.fieldName);

  set setterName(int v) => /*1:setterName(inlined)*/ fieldName = v;
}

@pragma('dart2js:noInline')
confuse(x) => x;

main() {
  confuse(new MyClass(3));
  var m = confuse(null);
  m. /*0:main*/ setterName = 2;
  print(m.fieldName);
}
