// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: closure:[exact=JSUInt31|powerset={I}{O}]*/
int closure(
  int
  /*spec.Union([exact=JSNumNotInt|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
  /*prod.[exact=JSUInt31|powerset={I}{O}]*/
  x,
) {
  return x;
}

class A {
  static const DEFAULT = const {'fun': closure};

  /*member: A.map:Dictionary([subclass=ConstantMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "fun", powerset: {I}{O}), value: [null|subclass=Closure|powerset={null}{N}{O}], map: {fun: [subclass=Closure|powerset={N}{O}]}, powerset: {N}{O})*/
  final map;

  /*member: A.:[exact=A|powerset={N}{O}]*/
  A([/*[null|powerset={null}]*/ maparg])
    : map = maparg == null ? DEFAULT : maparg;
}

/*member: main:[null|powerset={null}]*/
main() {
  var a = A();
  a. /*[exact=A|powerset={N}{O}]*/ map
  /*Dictionary([subclass=ConstantMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "fun", powerset: {I}{O}), value: [null|subclass=Closure|powerset={null}{N}{O}], map: {fun: [subclass=Closure|powerset={N}{O}]}, powerset: {N}{O})*/
  ['fun'](3.3);
  print(closure(22));
}
