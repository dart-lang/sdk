// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*kernel.class: Class:needsArgs*/
/*!kernel.class: Class:*/
class Class<T> {
  /*kernel.element: Class.:needsSignature*/
  /*!kernel.element: Class.:*/
  Class();
}

/*kernel.element: main:needsSignature*/
/*!kernel.element: main:*/
main() {
  /*!omit.needsSignature*/
  /*omit.*/
  local1() {}

  /*!omit.needsSignature*/
  /*omit.*/
  local2(int i, String s) => i;

  print('${local1.runtimeType}');
  local2(0, '');
  new Class();
}
