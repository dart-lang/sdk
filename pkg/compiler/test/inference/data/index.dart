// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton list.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSingle:[exact=JSUInt31|powerset={I}{O}]*/
listIndexSingle() {
  var list = [0];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 1, powerset: {I}{G})*/
  [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with multiple elements.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexMultiple:[exact=JSUInt31|powerset={I}{O}]*/
listIndexMultiple() {
  var list = [0, 1, 2, 3];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 4, powerset: {I}{G})*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with an out-of-range index.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexBad:[exact=JSUInt31|powerset={I}{O}]*/
listIndexBad() {
  var list = [0, 1];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 2, powerset: {I}{G})*/
  [3];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with mixed element types.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexMixed:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
listIndexMixed() {
  var list = [0, ''];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O}), length: 2, powerset: {I}{G})*/
  [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton map.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupSingle:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
mapLookupSingle() {
  var map = {0: 1};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSUInt31|powerset={I}{O}], value: [null|exact=JSUInt31|powerset={null}{I}{O}], powerset: {N}{O})*/
  [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with multiple entries.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMultiple:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
mapLookupMultiple() {
  var map = {0: 1, 2: 3, 4: 5};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSUInt31|powerset={I}{O}], value: [null|exact=JSUInt31|powerset={null}{I}{O}], powerset: {N}{O})*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMissing:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
mapLookupMissing() {
  var map = {0: 1};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSUInt31|powerset={I}{O}], value: [null|exact=JSUInt31|powerset={null}{I}{O}], powerset: {N}{O})*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with mixed key types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMixedKeys:[null|exact=JSUInt31|powerset={null}{I}{O}]*/
mapLookupMixedKeys() {
  var map = {0: 1, '': 2};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}{O}], key: Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O}), value: [null|exact=JSUInt31|powerset={null}{I}{O}], powerset: {N}{O})*/
  [''];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with mixed value types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMixedValues:Union(null, [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{O})*/
mapLookupMixedValues() {
  var map = {0: 1, 2: ''};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSUInt31|powerset={I}{O}], value: Union(null, [exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {null}{I}{O}), powerset: {N}{O})*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryLookupSingle:Value([exact=JSString|powerset={I}{O}], value: "bar", powerset: {I}{O})*/
dictionaryLookupSingle() {
  var map = {'foo': 'bar'};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "foo", powerset: {I}{O}), value: Value([null|exact=JSString|powerset={null}{I}{O}], value: "bar", powerset: {null}{I}{O}), map: {foo: Value([exact=JSString|powerset={I}{O}], value: "bar", powerset: {I}{O})}, powerset: {N}{O})*/
  ['foo'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryLookupMultiple:Value([exact=JSString|powerset={I}{O}], value: "boz", powerset: {I}{O})*/
dictionaryLookupMultiple() {
  var map = {'foo': 'bar', 'baz': 'boz'};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: [null|exact=JSString|powerset={null}{I}{O}], map: {foo: Value([exact=JSString|powerset={I}{O}], value: "bar", powerset: {I}{O}), baz: Value([exact=JSString|powerset={I}{O}], value: "boz", powerset: {I}{O})}, powerset: {N}{O})*/
  ['baz'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with String keys with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryLookupMissing:[null|powerset={null}]*/
dictionaryLookupMissing() {
  var map = {'foo': 'bar', 'baz': 'boz'};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: [null|exact=JSString|powerset={null}{I}{O}], map: {foo: Value([exact=JSString|powerset={I}{O}], value: "bar", powerset: {I}{O}), baz: Value([exact=JSString|powerset={I}{O}], value: "boz", powerset: {I}{O})}, powerset: {N}{O})*/
  ['unknown'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a string-to-int map.
////////////////////////////////////////////////////////////////////////////////

/*member: intDictionaryLookupSingle:[exact=JSUInt31|powerset={I}{O}]*/
intDictionaryLookupSingle() {
  var map = {'foo': 0};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "foo", powerset: {I}{O}), value: [null|exact=JSUInt31|powerset={null}{I}{O}], map: {foo: [exact=JSUInt31|powerset={I}{O}]}, powerset: {N}{O})*/
  ['foo'];
}

////////////////////////////////////////////////////////////////////////////////
// Index access on custom class.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}{O}]*/
class Class1 {
  /*member: Class1.[]:[exact=JSUInt31|powerset={I}{O}]*/
  operator [](/*[exact=JSUInt31|powerset={I}{O}]*/ index) => index;
}

/*member: customIndex:[exact=JSUInt31|powerset={I}{O}]*/
customIndex() => Class1() /*[exact=Class1|powerset={N}{O}]*/ [42];

////////////////////////////////////////////////////////////////////////////////
// Index access on custom class through `this`.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset={N}{O}]*/
class Class2 {
  /*member: Class2.[]:[exact=JSUInt31|powerset={I}{O}]*/
  operator [](/*[exact=JSUInt31|powerset={I}{O}]*/ index) => index;

  /*member: Class2.method:[exact=JSUInt31|powerset={I}{O}]*/
  method() => this /*[exact=Class2|powerset={N}{O}]*/ [42];
}

/*member: customIndexThis:[exact=JSUInt31|powerset={I}{O}]*/
customIndexThis() =>
    Class2(). /*invoke: [exact=Class2|powerset={N}{O}]*/ method();

/*member: main:[null|powerset={null}]*/
main() {
  listIndexSingle();
  listIndexMultiple();
  listIndexBad();
  listIndexMixed();

  mapLookupSingle();
  mapLookupMultiple();
  mapLookupMissing();
  mapLookupMixedKeys();
  mapLookupMixedValues();

  dictionaryLookupSingle();
  dictionaryLookupMultiple();
  dictionaryLookupMissing();

  intDictionaryLookupSingle();

  customIndex();
  customIndexThis();
}
