// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Imported by main.dart.

library deferred_class_library;

/*class: MyClass:
 class_unit=1{lib},
 type_unit=1{lib}
*/
class MyClass {
  /*member: MyClass.:member_unit=1{lib}*/
  const MyClass();

  /*member: MyClass.foo:member_unit=1{lib}*/
  foo(x) {
    print('MyClass.foo($x)');
    return (x - 3) ~/ 2;
  }
}
