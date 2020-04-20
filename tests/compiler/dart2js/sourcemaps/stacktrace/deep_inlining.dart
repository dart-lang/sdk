// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class MyClass {}

@pragma('dart2js:noInline')
method3() {
  /*4:method3*/ throw new MyClass();
}

method2() => /*3:method2*/ method3();
method4() {
  /*2:method4(inlined)*/ method2();
}

method1() {
  print('hi');
  /*1:method1(inlined)*/ method4();
}

main() => /*0:main*/ method1();
