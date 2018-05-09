// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Imported by deferred_class.dart.

library deferred_class_library;

/*class: MyClass:OutputUnit(1, {lib})*/
class MyClass {
  /*element: MyClass.:OutputUnit(1, {lib})*/
  const MyClass();

  /*element: MyClass.foo:OutputUnit(1, {lib})*/
  foo(x) {
    print('MyClass.foo($x)');
    return (x - 3) ~/ 2;
  }
}
