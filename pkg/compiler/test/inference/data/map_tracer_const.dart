// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: closure:[exact=JSUInt31]*/
int closure(
    int
        /*spec.Union([exact=JSDouble], [exact=JSUInt31])*/
        /*prod.[exact=JSUInt31]*/
        x) {
  return x;
}

class A {
  static const DEFAULT = const {'fun': closure};

  /*member: A.map:Dictionary([subclass=ConstantMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
  final map;

  /*member: A.:[exact=A]*/
  A([/*[null]*/ maparg]) : map = maparg == null ? DEFAULT : maparg;
}

/*member: main:[null]*/
main() {
  var a = new A();
  a. /*[exact=A]*/ map
      /*Dictionary([subclass=ConstantMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
      ['fun'](3.3);
  print(closure(22));
}
