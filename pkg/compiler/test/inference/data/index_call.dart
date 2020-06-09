// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  listIndexCall();
  listIndexExplicitCall();
  multiListIndex();
  multiListIndexCall();
  multiMapIndex();
  multiMapIndexCall();
  multiMapListIndexCall();
}

/*member: listIndexCall:[null|subclass=Object]*/
listIndexCall() {
  var closure = /*[exact=JSUInt31]*/ ({/*[exact=JSUInt31]*/ a}) => a;
  var a = [closure];
  return a /*Container([exact=JSExtendableArray], element: [subclass=Closure], length: 1)*/
      [0](a: 0);
}

/*member: listIndexExplicitCall:[null|subclass=Object]*/
listIndexExplicitCall() {
  var closure = /*[exact=JSUInt31]*/ ({/*[exact=JSUInt31]*/ b}) => b;
  var a = [closure];
  return a /*Container([exact=JSExtendableArray], element: [subclass=Closure], length: 1)*/
          [0]
      .call(b: 0);
}

/*member: multiListIndex:[subclass=JSPositiveInt]*/
multiListIndex() {
  var a = [
    [0]
  ];
  return a
              /*Container([exact=JSExtendableArray], element: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1), length: 1)*/
              [0]
          /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
          [0]
      . /*invoke: [exact=JSUInt31]*/ abs();
}

/*member: multiListIndexCall:[null|subclass=Object]*/
multiListIndexCall() {
  var closure = /*[exact=JSUInt31]*/ ({/*[exact=JSUInt31]*/ c}) => c;
  var a = [
    [closure]
  ];
  return a
          /*Container([exact=JSExtendableArray], element: Container([exact=JSExtendableArray], element: [subclass=Closure], length: 1), length: 1)*/
          [0]
      /*Container([exact=JSExtendableArray], element: [subclass=Closure], length: 1)*/
      [0](c: 0);
}

/*member: multiMapIndex:[subclass=JSPositiveInt]*/
multiMapIndex() {
  var a = {
    'a': {'b': 0}
  };
  return a /*Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "a"), value: Dictionary([null|subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "b"), value: [null|exact=JSUInt31], map: {b: [exact=JSUInt31]}), map: {a: Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "b"), value: [null|exact=JSUInt31], map: {b: [exact=JSUInt31]})})*/
              ['a']
          /*Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "b"), value: [null|exact=JSUInt31], map: {b: [exact=JSUInt31]})*/
          ['b']
      . /*invoke: [exact=JSUInt31]*/
      abs();
}

/*member: multiMapIndexCall:[null|subclass=Object]*/
multiMapIndexCall() {
  var closure = /*[exact=JSUInt31]*/ ({/*[exact=JSUInt31]*/ d}) => d;
  var a = {
    'a': {'b': closure}
  };
  return a /*Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "a"), value: Dictionary([null|subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "b"), value: [null|subclass=Closure], map: {b: [subclass=Closure]}), map: {a: Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "b"), value: [null|subclass=Closure], map: {b: [subclass=Closure]})})*/
          ['a']
      /*Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "b"), value: [null|subclass=Closure], map: {b: [subclass=Closure]})*/
      ['b'](d: 0);
}

/*member: multiMapListIndexCall:[null|subclass=Object]*/
multiMapListIndexCall() {
  var closure = /*[exact=JSUInt31]*/ ({/*[exact=JSUInt31]*/ d}) => d;
  var a = {
    'a': [closure]
  };
  return a /*Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "a"), value: Container([null|exact=JSExtendableArray], element: [subclass=Closure], length: 1), map: {a: Container([exact=JSExtendableArray], element: [subclass=Closure], length: 1)})*/
          ['a']
      /*Container([exact=JSExtendableArray], element: [subclass=Closure], length: 1)*/
      [0](d: 0);
}
