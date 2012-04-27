// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check type bounds when invoking a factory method

interface Foo {}

interface IA<T> default A<T extends Foo> { IA(); }

class A<T extends Foo> implements IA<T> {
   factory A(){}
}
 
main() {
  var result = new IA<String>();  /// 01: static type warning
}
