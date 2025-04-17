// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: closure:[exact=JSUInt31|powerset={I}]*/
int closure(
  int
  /*spec.Union([exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
  /*prod.[exact=JSUInt31|powerset={I}]*/
  x,
) {
  return x;
}

class A {
  static const DEFAULT = const {'fun': closure};

  /*member: A.map:Dictionary([subclass=ConstantMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "fun", powerset: {I}), value: [null|subclass=Closure|powerset={null}{N}], map: {fun: [subclass=Closure|powerset={N}]}, powerset: {N})*/
  final map;

  /*member: A.:[exact=A|powerset={N}]*/
  A([/*[null|powerset={null}]*/ maparg])
    : map = maparg == null ? DEFAULT : maparg;
}

/*member: main:[null|powerset={null}]*/
main() {
  var a = A();
  a. /*[exact=A|powerset={N}]*/ map
  /*Dictionary([subclass=ConstantMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "fun", powerset: {I}), value: [null|subclass=Closure|powerset={null}{N}], map: {fun: [subclass=Closure|powerset={N}]}, powerset: {N})*/
  ['fun'](3.3);
  print(closure(22));
}
