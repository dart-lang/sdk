// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: closure:[exact=JSUInt31|powerset=0]*/
int closure(
  int
  /*spec.Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  /*prod.[exact=JSUInt31|powerset=0]*/
  x,
) {
  return x;
}

class A {
  static const DEFAULT = const {'fun': closure};

  /*member: A.map:Dictionary([subclass=ConstantMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "fun", powerset: 0), value: [null|subclass=Closure|powerset=1], map: {fun: [subclass=Closure|powerset=0]}, powerset: 0)*/
  final map;

  /*member: A.:[exact=A|powerset=0]*/
  A([/*[null|powerset=1]*/ maparg]) : map = maparg == null ? DEFAULT : maparg;
}

/*member: main:[null|powerset=1]*/
main() {
  var a = A();
  a. /*[exact=A|powerset=0]*/ map
  /*Dictionary([subclass=ConstantMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "fun", powerset: 0), value: [null|subclass=Closure|powerset=1], map: {fun: [subclass=Closure|powerset=0]}, powerset: 0)*/
  ['fun'](3.3);
  print(closure(22));
}
