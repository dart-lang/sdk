// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: closure:[exact=JSUInt31|powerset={I}{O}{N}]*/
int closure(
  int
  /*spec.Union([exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/
  /*prod.[exact=JSUInt31|powerset={I}{O}{N}]*/
  x,
) {
  return x;
}

class A {
  static const DEFAULT = const {'fun': closure};

  /*member: A.map:Dictionary([subclass=ConstantMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "fun", powerset: {I}{O}{I}), value: [null|subclass=Closure|powerset={null}{N}{O}{N}], map: {fun: [subclass=Closure|powerset={N}{O}{N}]}, powerset: {N}{O}{N})*/
  final map;

  /*member: A.:[exact=A|powerset={N}{O}{N}]*/
  A([/*[null|powerset={null}]*/ maparg])
    : map = maparg == null ? DEFAULT : maparg;
}

/*member: main:[null|powerset={null}]*/
main() {
  var a = A();
  a. /*[exact=A|powerset={N}{O}{N}]*/ map
  /*Dictionary([subclass=ConstantMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "fun", powerset: {I}{O}{I}), value: [null|subclass=Closure|powerset={null}{N}{O}{N}], map: {fun: [subclass=Closure|powerset={N}{O}{N}]}, powerset: {N}{O}{N})*/
  ['fun'](3.3);
  print(closure(22));
}
