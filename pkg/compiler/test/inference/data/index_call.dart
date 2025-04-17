// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  listIndexCall();
  listIndexExplicitCall();
  multiListIndex();
  multiListIndexCall();
  multiMapIndex();
  multiMapIndexCall();
  multiMapListIndexCall();
}

/*member: listIndexCall:[null|subclass=Object|powerset={null}{IN}]*/
listIndexCall() {
  var closure = /*[exact=JSUInt31|powerset={I}]*/
      ({/*[exact=JSUInt31|powerset={I}]*/ a}) => a;
  var a = [closure];
  return a /*Container([exact=JSExtendableArray|powerset={I}], element: [subclass=Closure|powerset={N}], length: 1, powerset: {I})*/ [0](
    a: 0,
  );
}

/*member: listIndexExplicitCall:[null|subclass=Object|powerset={null}{IN}]*/
listIndexExplicitCall() {
  var closure = /*[exact=JSUInt31|powerset={I}]*/
      ({/*[exact=JSUInt31|powerset={I}]*/ b}) => b;
  var a = [closure];
  return a /*Container([exact=JSExtendableArray|powerset={I}], element: [subclass=Closure|powerset={N}], length: 1, powerset: {I})*/ [0]
      .call(b: 0);
}

/*member: multiListIndex:[subclass=JSPositiveInt|powerset={I}]*/
multiListIndex() {
  var a = [
    [0],
  ];
  return a
      /*Container([exact=JSExtendableArray|powerset={I}], element: Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I}), length: 1, powerset: {I})*/
      [0]
      /*Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
      [0]
      . /*invoke: [exact=JSUInt31|powerset={I}]*/ abs();
}

/*member: multiListIndexCall:[null|subclass=Object|powerset={null}{IN}]*/
multiListIndexCall() {
  var closure = /*[exact=JSUInt31|powerset={I}]*/
      ({/*[exact=JSUInt31|powerset={I}]*/ c}) => c;
  var a = [
    [closure],
  ];
  return a
  /*Container([exact=JSExtendableArray|powerset={I}], element: Container([exact=JSExtendableArray|powerset={I}], element: [subclass=Closure|powerset={N}], length: 1, powerset: {I}), length: 1, powerset: {I})*/
  [0]
  /*Container([exact=JSExtendableArray|powerset={I}], element: [subclass=Closure|powerset={N}], length: 1, powerset: {I})*/
  [0](c: 0);
}

/*member: multiMapIndex:[subclass=JSPositiveInt|powerset={I}]*/
multiMapIndex() {
  var a = {
    'a': {'b': 0},
  };
  return a /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "a", powerset: {I}), value: Dictionary([null|exact=JsLinkedHashMap|powerset={null}{N}], key: Value([exact=JSString|powerset={I}], value: "b", powerset: {I}), value: [null|exact=JSUInt31|powerset={null}{I}], map: {b: [exact=JSUInt31|powerset={I}]}, powerset: {null}{N}), map: {a: Dictionary([exact=JsLinkedHashMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "b", powerset: {I}), value: [null|exact=JSUInt31|powerset={null}{I}], map: {b: [exact=JSUInt31|powerset={I}]}, powerset: {N})}, powerset: {N})*/ ['a']!
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "b", powerset: {I}), value: [null|exact=JSUInt31|powerset={null}{I}], map: {b: [exact=JSUInt31|powerset={I}]}, powerset: {N})*/
      ['b']!
      . /*invoke: [exact=JSUInt31|powerset={I}]*/ abs();
}

/*member: multiMapIndexCall:[null|subclass=Object|powerset={null}{IN}]*/
multiMapIndexCall() {
  var closure = /*[exact=JSUInt31|powerset={I}]*/
      ({/*[exact=JSUInt31|powerset={I}]*/ d}) => d;
  var a = {
    'a': {'b': closure},
  };
  return a /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "a", powerset: {I}), value: Dictionary([null|exact=JsLinkedHashMap|powerset={null}{N}], key: Value([exact=JSString|powerset={I}], value: "b", powerset: {I}), value: [null|subclass=Closure|powerset={null}{N}], map: {b: [subclass=Closure|powerset={N}]}, powerset: {null}{N}), map: {a: Dictionary([exact=JsLinkedHashMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "b", powerset: {I}), value: [null|subclass=Closure|powerset={null}{N}], map: {b: [subclass=Closure|powerset={N}]}, powerset: {N})}, powerset: {N})*/ ['a']!
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "b", powerset: {I}), value: [null|subclass=Closure|powerset={null}{N}], map: {b: [subclass=Closure|powerset={N}]}, powerset: {N})*/
  ['b']!(d: 0);
}

/*member: multiMapListIndexCall:[null|subclass=Object|powerset={null}{IN}]*/
multiMapListIndexCall() {
  var closure = /*[exact=JSUInt31|powerset={I}]*/
      ({/*[exact=JSUInt31|powerset={I}]*/ d}) => d;
  var a = {
    'a': [closure],
  };
  return a /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "a", powerset: {I}), value: Container([null|exact=JSExtendableArray|powerset={null}{I}], element: [subclass=Closure|powerset={N}], length: 1, powerset: {null}{I}), map: {a: Container([exact=JSExtendableArray|powerset={I}], element: [subclass=Closure|powerset={N}], length: 1, powerset: {I})}, powerset: {N})*/ ['a']!
  /*Container([exact=JSExtendableArray|powerset={I}], element: [subclass=Closure|powerset={N}], length: 1, powerset: {I})*/
  [0](d: 0);
}
