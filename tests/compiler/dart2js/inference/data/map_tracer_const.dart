// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: closure:[exact=JSUInt31]*/
int closure(
    int
        /*strong.Union([exact=JSDouble], [exact=JSUInt31])*/
        /*omit.[exact=JSUInt31]*/
        /*strongConst.Union([exact=JSDouble], [exact=JSUInt31])*/
        /*omitConst.[exact=JSUInt31]*/
        x) {
  return x;
}

class A {
  /*strong.element: A.DEFAULT:Dictionary([subclass=ConstantMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
  /*omit.element: A.DEFAULT:Dictionary([subclass=ConstantMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
  static const DEFAULT = const {'fun': closure};

  /*strong.element: A.map:Dictionary([subclass=ConstantMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
  /*omit.element: A.map:Dictionary([subclass=ConstantMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
  /*strongConst.element: A.map:Dictionary([exact=ConstantStringMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
  /*omitConst.element: A.map:Dictionary([exact=ConstantStringMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
  final map;

  /*element: A.:[exact=A]*/
  A([/*[null]*/ maparg]) : map = maparg == null ? DEFAULT : maparg;
}

/*element: main:[null]*/
main() {
  var a = new A();
  a. /*[exact=A]*/ map
      /*strong.Dictionary([subclass=ConstantMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
      /*omit.Dictionary([subclass=ConstantMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
      /*strongConst.Dictionary([exact=ConstantStringMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
      /*omitConst.Dictionary([exact=ConstantStringMap], key: Value([exact=JSString], value: "fun"), value: [null|subclass=Closure], map: {fun: [subclass=Closure]})*/
      ['fun'](3.3);
  print(closure(22));
}
