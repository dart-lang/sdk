// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*kernel.class: Class:needsArgs*/
/*strong.class: Class:*/
/*omit.class: Class:*/
class Class<T> {
  /*kernel.element: Class.:needsSignature*/
  /*strong.element: Class.:*/
  /*omit.element: Class.:*/
  Class();
}

/*kernel.element: main:needsSignature*/
/*strong.element: main:*/
/*omit.element: main:*/
main() {
  /*kernel.needsSignature*/
  /*strong.needsArgs,needsSignature*/
  /*omit.*/
  local1<T>() {}

  /*kernel.needsSignature*/
  /*strong.needsArgs,needsSignature,selectors=[Selector(call, call, arity=2, types=1)]*/
  /*omit.*/
  local2<T>(t, s) => t;

  print('${local1.runtimeType}');
  local2(0, '');
  new Class();
}
