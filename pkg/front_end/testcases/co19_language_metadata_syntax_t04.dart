/*
 * Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */
/**
 * @assertion
 *  metadata:
 *   (‘@’ qualified (‘.’ identifier)? (arguments)?)*
 *   ;
 * @description Check that it is a compile time error, if @ is missing
 * @compile-error
 * @author a.semenov@unipro.ru
 */

class A {
  const A();
}

A()
class B {}

main() {
}
