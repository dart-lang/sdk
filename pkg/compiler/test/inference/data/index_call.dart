// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  listIndexCall();
  listIndexExplicitCall();
  multiListIndex();
  multiListIndexCall();
  multiMapIndex();
  multiMapIndexCall();
  multiMapListIndexCall();
}

/*member: listIndexCall:[null|subclass=Object|powerset=1]*/
listIndexCall() {
  var closure = /*[exact=JSUInt31|powerset=0]*/
      ({/*[exact=JSUInt31|powerset=0]*/ a}) => a;
  var a = [closure];
  return a /*Container([exact=JSExtendableArray|powerset=0], element: [subclass=Closure|powerset=0], length: 1, powerset: 0)*/ [0](
    a: 0,
  );
}

/*member: listIndexExplicitCall:[null|subclass=Object|powerset=1]*/
listIndexExplicitCall() {
  var closure = /*[exact=JSUInt31|powerset=0]*/
      ({/*[exact=JSUInt31|powerset=0]*/ b}) => b;
  var a = [closure];
  return a /*Container([exact=JSExtendableArray|powerset=0], element: [subclass=Closure|powerset=0], length: 1, powerset: 0)*/ [0]
      .call(b: 0);
}

/*member: multiListIndex:[subclass=JSPositiveInt|powerset=0]*/
multiListIndex() {
  var a = [
    [0],
  ];
  return a
      /*Container([exact=JSExtendableArray|powerset=0], element: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0), length: 1, powerset: 0)*/
      [0]
      /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
      [0]
      . /*invoke: [exact=JSUInt31|powerset=0]*/ abs();
}

/*member: multiListIndexCall:[null|subclass=Object|powerset=1]*/
multiListIndexCall() {
  var closure = /*[exact=JSUInt31|powerset=0]*/
      ({/*[exact=JSUInt31|powerset=0]*/ c}) => c;
  var a = [
    [closure],
  ];
  return a
  /*Container([exact=JSExtendableArray|powerset=0], element: Container([exact=JSExtendableArray|powerset=0], element: [subclass=Closure|powerset=0], length: 1, powerset: 0), length: 1, powerset: 0)*/
  [0]
  /*Container([exact=JSExtendableArray|powerset=0], element: [subclass=Closure|powerset=0], length: 1, powerset: 0)*/
  [0](c: 0);
}

/*member: multiMapIndex:[subclass=JSPositiveInt|powerset=0]*/
multiMapIndex() {
  var a = {
    'a': {'b': 0},
  };
  return a /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "a", powerset: 0), value: Dictionary([null|exact=JsLinkedHashMap|powerset=1], key: Value([exact=JSString|powerset=0], value: "b", powerset: 0), value: [null|exact=JSUInt31|powerset=1], map: {b: [exact=JSUInt31|powerset=0]}, powerset: 1), map: {a: Dictionary([exact=JsLinkedHashMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "b", powerset: 0), value: [null|exact=JSUInt31|powerset=1], map: {b: [exact=JSUInt31|powerset=0]}, powerset: 0)}, powerset: 0)*/ ['a']!
      /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "b", powerset: 0), value: [null|exact=JSUInt31|powerset=1], map: {b: [exact=JSUInt31|powerset=0]}, powerset: 0)*/
      ['b']!
      . /*invoke: [exact=JSUInt31|powerset=0]*/ abs();
}

/*member: multiMapIndexCall:[null|subclass=Object|powerset=1]*/
multiMapIndexCall() {
  var closure = /*[exact=JSUInt31|powerset=0]*/
      ({/*[exact=JSUInt31|powerset=0]*/ d}) => d;
  var a = {
    'a': {'b': closure},
  };
  return a /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "a", powerset: 0), value: Dictionary([null|exact=JsLinkedHashMap|powerset=1], key: Value([exact=JSString|powerset=0], value: "b", powerset: 0), value: [null|subclass=Closure|powerset=1], map: {b: [subclass=Closure|powerset=0]}, powerset: 1), map: {a: Dictionary([exact=JsLinkedHashMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "b", powerset: 0), value: [null|subclass=Closure|powerset=1], map: {b: [subclass=Closure|powerset=0]}, powerset: 0)}, powerset: 0)*/ ['a']!
  /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "b", powerset: 0), value: [null|subclass=Closure|powerset=1], map: {b: [subclass=Closure|powerset=0]}, powerset: 0)*/
  ['b']!(d: 0);
}

/*member: multiMapListIndexCall:[null|subclass=Object|powerset=1]*/
multiMapListIndexCall() {
  var closure = /*[exact=JSUInt31|powerset=0]*/
      ({/*[exact=JSUInt31|powerset=0]*/ d}) => d;
  var a = {
    'a': [closure],
  };
  return a /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "a", powerset: 0), value: Container([null|exact=JSExtendableArray|powerset=1], element: [subclass=Closure|powerset=0], length: 1, powerset: 1), map: {a: Container([exact=JSExtendableArray|powerset=0], element: [subclass=Closure|powerset=0], length: 1, powerset: 0)}, powerset: 0)*/ ['a']!
  /*Container([exact=JSExtendableArray|powerset=0], element: [subclass=Closure|powerset=0], length: 1, powerset: 0)*/
  [0](d: 0);
}
