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

/*member: listIndexCall:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
listIndexCall() {
  var closure = /*[exact=JSUInt31|powerset={I}{O}]*/
      ({/*[exact=JSUInt31|powerset={I}{O}]*/ a}) => a;
  var a = [closure];
  return a /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=Closure|powerset={N}{O}], length: 1, powerset: {I}{G})*/ [0](
    a: 0,
  );
}

/*member: listIndexExplicitCall:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
listIndexExplicitCall() {
  var closure = /*[exact=JSUInt31|powerset={I}{O}]*/
      ({/*[exact=JSUInt31|powerset={I}{O}]*/ b}) => b;
  var a = [closure];
  return a /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=Closure|powerset={N}{O}], length: 1, powerset: {I}{G})*/ [0]
      .call(b: 0);
}

/*member: multiListIndex:[subclass=JSPositiveInt|powerset={I}{O}]*/
multiListIndex() {
  var a = [
    [0],
  ];
  return a
      /*Container([exact=JSExtendableArray|powerset={I}{G}], element: Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 1, powerset: {I}{G}), length: 1, powerset: {I}{G})*/
      [0]
      /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 1, powerset: {I}{G})*/
      [0]
      . /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ abs();
}

/*member: multiListIndexCall:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
multiListIndexCall() {
  var closure = /*[exact=JSUInt31|powerset={I}{O}]*/
      ({/*[exact=JSUInt31|powerset={I}{O}]*/ c}) => c;
  var a = [
    [closure],
  ];
  return a
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=Closure|powerset={N}{O}], length: 1, powerset: {I}{G}), length: 1, powerset: {I}{G})*/
  [0]
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=Closure|powerset={N}{O}], length: 1, powerset: {I}{G})*/
  [0](c: 0);
}

/*member: multiMapIndex:[subclass=JSPositiveInt|powerset={I}{O}]*/
multiMapIndex() {
  var a = {
    'a': {'b': 0},
  };
  return a /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "a", powerset: {I}{O}), value: Dictionary([null|exact=JsLinkedHashMap|powerset={null}{N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "b", powerset: {I}{O}), value: [null|exact=JSUInt31|powerset={null}{I}{O}], map: {b: [exact=JSUInt31|powerset={I}{O}]}, powerset: {null}{N}{O}), map: {a: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "b", powerset: {I}{O}), value: [null|exact=JSUInt31|powerset={null}{I}{O}], map: {b: [exact=JSUInt31|powerset={I}{O}]}, powerset: {N}{O})}, powerset: {N}{O})*/ ['a']!
      /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "b", powerset: {I}{O}), value: [null|exact=JSUInt31|powerset={null}{I}{O}], map: {b: [exact=JSUInt31|powerset={I}{O}]}, powerset: {N}{O})*/
      ['b']!
      . /*invoke: [exact=JSUInt31|powerset={I}{O}]*/ abs();
}

/*member: multiMapIndexCall:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
multiMapIndexCall() {
  var closure = /*[exact=JSUInt31|powerset={I}{O}]*/
      ({/*[exact=JSUInt31|powerset={I}{O}]*/ d}) => d;
  var a = {
    'a': {'b': closure},
  };
  return a /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "a", powerset: {I}{O}), value: Dictionary([null|exact=JsLinkedHashMap|powerset={null}{N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "b", powerset: {I}{O}), value: [null|subclass=Closure|powerset={null}{N}{O}], map: {b: [subclass=Closure|powerset={N}{O}]}, powerset: {null}{N}{O}), map: {a: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "b", powerset: {I}{O}), value: [null|subclass=Closure|powerset={null}{N}{O}], map: {b: [subclass=Closure|powerset={N}{O}]}, powerset: {N}{O})}, powerset: {N}{O})*/ ['a']!
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "b", powerset: {I}{O}), value: [null|subclass=Closure|powerset={null}{N}{O}], map: {b: [subclass=Closure|powerset={N}{O}]}, powerset: {N}{O})*/
  ['b']!(d: 0);
}

/*member: multiMapListIndexCall:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
multiMapListIndexCall() {
  var closure = /*[exact=JSUInt31|powerset={I}{O}]*/
      ({/*[exact=JSUInt31|powerset={I}{O}]*/ d}) => d;
  var a = {
    'a': [closure],
  };
  return a /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "a", powerset: {I}{O}), value: Container([null|exact=JSExtendableArray|powerset={null}{I}{G}], element: [subclass=Closure|powerset={N}{O}], length: 1, powerset: {null}{I}{G}), map: {a: Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=Closure|powerset={N}{O}], length: 1, powerset: {I}{G})}, powerset: {N}{O})*/ ['a']!
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [subclass=Closure|powerset={N}{O}], length: 1, powerset: {I}{G})*/
  [0](d: 0);
}
