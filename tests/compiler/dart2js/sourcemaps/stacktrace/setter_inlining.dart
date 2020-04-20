// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class MyClass {
  int fieldName;

  MyClass(this.fieldName);

  @pragma('dart2js:tryInline')
  set setterName(int v) => fieldName = v;
}

@pragma('dart2js:noInline')
confuse(x) => x;

main() {
  confuse(new MyClass(3));
  var m = confuse(null);
  m. /*0:main*/ setterName = 2;
  print(m.fieldName);
}
