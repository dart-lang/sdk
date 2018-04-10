// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*ast.element: closure:Union([exact=JSDouble], [exact=JSUInt31])*/
/*kernel.element: closure:Union([exact=JSDouble], [exact=JSUInt31])*/
/*strong.element: closure:[exact=JSUInt31]*/
int closure(int /*Union([exact=JSDouble], [exact=JSUInt31])*/ x) {
  return x;
}

class A {
  /*element: A.DEFAULT:Dictionary([subclass=ConstantMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
  static const DEFAULT = const {'fun': closure};

  /*element: A.map:Dictionary([subclass=ConstantMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
  final map;

  /*element: A.:[exact=A]*/
  A([/*[null]*/ maparg]) : map = maparg == null ? DEFAULT : maparg;
}

/*element: main:[null]*/
main() {
  var a = new A();
  a. /*[exact=A]*/ map
      /*Dictionary([subclass=ConstantMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
      ['fun'](3.3);
  print(closure(22));
}
