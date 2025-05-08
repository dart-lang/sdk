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

/*member: listIndexCall:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
listIndexCall() {
  var closure = /*[exact=JSUInt31|powerset={I}{O}{N}]*/
      ({/*[exact=JSUInt31|powerset={I}{O}{N}]*/ a}) => a;
  var a = [closure];
  return a /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=Closure|powerset={N}{O}{N}], length: 1, powerset: {I}{G}{M})*/ [0](
    a: 0,
  );
}

/*member: listIndexExplicitCall:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
listIndexExplicitCall() {
  var closure = /*[exact=JSUInt31|powerset={I}{O}{N}]*/
      ({/*[exact=JSUInt31|powerset={I}{O}{N}]*/ b}) => b;
  var a = [closure];
  return a /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=Closure|powerset={N}{O}{N}], length: 1, powerset: {I}{G}{M})*/ [0]
      .call(b: 0);
}

/*member: multiListIndex:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
multiListIndex() {
  var a = [
    [0],
  ];
  return a
      /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M}), length: 1, powerset: {I}{G}{M})*/
      [0]
      /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
      [0]
      . /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ abs();
}

/*member: multiListIndexCall:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
multiListIndexCall() {
  var closure = /*[exact=JSUInt31|powerset={I}{O}{N}]*/
      ({/*[exact=JSUInt31|powerset={I}{O}{N}]*/ c}) => c;
  var a = [
    [closure],
  ];
  return a
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=Closure|powerset={N}{O}{N}], length: 1, powerset: {I}{G}{M}), length: 1, powerset: {I}{G}{M})*/
  [0]
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=Closure|powerset={N}{O}{N}], length: 1, powerset: {I}{G}{M})*/
  [0](c: 0);
}

/*member: multiMapIndex:[subclass=JSPositiveInt|powerset={I}{O}{N}]*/
multiMapIndex() {
  var a = {
    'a': {'b': 0},
  };
  return a /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "a", powerset: {I}{O}{I}), value: Dictionary([null|exact=JsLinkedHashMap|powerset={null}{N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "b", powerset: {I}{O}{I}), value: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], map: {b: [exact=JSUInt31|powerset={I}{O}{N}]}, powerset: {null}{N}{O}{N}), map: {a: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "b", powerset: {I}{O}{I}), value: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], map: {b: [exact=JSUInt31|powerset={I}{O}{N}]}, powerset: {N}{O}{N})}, powerset: {N}{O}{N})*/ ['a']!
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "b", powerset: {I}{O}{I}), value: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], map: {b: [exact=JSUInt31|powerset={I}{O}{N}]}, powerset: {N}{O}{N})*/
      ['b']!
      . /*invoke: [exact=JSUInt31|powerset={I}{O}{N}]*/ abs();
}

/*member: multiMapIndexCall:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
multiMapIndexCall() {
  var closure = /*[exact=JSUInt31|powerset={I}{O}{N}]*/
      ({/*[exact=JSUInt31|powerset={I}{O}{N}]*/ d}) => d;
  var a = {
    'a': {'b': closure},
  };
  return a /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "a", powerset: {I}{O}{I}), value: Dictionary([null|exact=JsLinkedHashMap|powerset={null}{N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "b", powerset: {I}{O}{I}), value: [null|subclass=Closure|powerset={null}{N}{O}{N}], map: {b: [subclass=Closure|powerset={N}{O}{N}]}, powerset: {null}{N}{O}{N}), map: {a: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "b", powerset: {I}{O}{I}), value: [null|subclass=Closure|powerset={null}{N}{O}{N}], map: {b: [subclass=Closure|powerset={N}{O}{N}]}, powerset: {N}{O}{N})}, powerset: {N}{O}{N})*/ ['a']!
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "b", powerset: {I}{O}{I}), value: [null|subclass=Closure|powerset={null}{N}{O}{N}], map: {b: [subclass=Closure|powerset={N}{O}{N}]}, powerset: {N}{O}{N})*/
  ['b']!(d: 0);
}

/*member: multiMapListIndexCall:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
multiMapListIndexCall() {
  var closure = /*[exact=JSUInt31|powerset={I}{O}{N}]*/
      ({/*[exact=JSUInt31|powerset={I}{O}{N}]*/ d}) => d;
  var a = {
    'a': [closure],
  };
  return a /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "a", powerset: {I}{O}{I}), value: Container([null|exact=JSExtendableArray|powerset={null}{I}{G}{M}], element: [subclass=Closure|powerset={N}{O}{N}], length: 1, powerset: {null}{I}{G}{M}), map: {a: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=Closure|powerset={N}{O}{N}], length: 1, powerset: {I}{G}{M})}, powerset: {N}{O}{N})*/ ['a']!
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [subclass=Closure|powerset={N}{O}{N}], length: 1, powerset: {I}{G}{M})*/
  [0](d: 0);
}
