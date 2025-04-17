// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton list.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSingle:[exact=JSUInt31|powerset={I}]*/
listIndexSingle() {
  var list = [0];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
  [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with multiple elements.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexMultiple:[exact=JSUInt31|powerset={I}]*/
listIndexMultiple() {
  var list = [0, 1, 2, 3];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 4, powerset: {I})*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with an out-of-range index.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexBad:[exact=JSUInt31|powerset={I}]*/
listIndexBad() {
  var list = [0, 1];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 2, powerset: {I})*/
  [3];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with mixed element types.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexMixed:Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
listIndexMixed() {
  var list = [0, ''];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}], element: Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I}), length: 2, powerset: {I})*/
  [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton map.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupSingle:[null|exact=JSUInt31|powerset={null}{I}]*/
mapLookupSingle() {
  var map = {0: 1};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSUInt31|powerset={I}], value: [null|exact=JSUInt31|powerset={null}{I}], powerset: {N})*/
  [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with multiple entries.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMultiple:[null|exact=JSUInt31|powerset={null}{I}]*/
mapLookupMultiple() {
  var map = {0: 1, 2: 3, 4: 5};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSUInt31|powerset={I}], value: [null|exact=JSUInt31|powerset={null}{I}], powerset: {N})*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMissing:[null|exact=JSUInt31|powerset={null}{I}]*/
mapLookupMissing() {
  var map = {0: 1};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSUInt31|powerset={I}], value: [null|exact=JSUInt31|powerset={null}{I}], powerset: {N})*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with mixed key types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMixedKeys:[null|exact=JSUInt31|powerset={null}{I}]*/
mapLookupMixedKeys() {
  var map = {0: 1, '': 2};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}], key: Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I}), value: [null|exact=JSUInt31|powerset={null}{I}], powerset: {N})*/
  [''];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with mixed value types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMixedValues:Union(null, [exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {null}{I})*/
mapLookupMixedValues() {
  var map = {0: 1, 2: ''};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSUInt31|powerset={I}], value: Union(null, [exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {null}{I}), powerset: {N})*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryLookupSingle:Value([exact=JSString|powerset={I}], value: "bar", powerset: {I})*/
dictionaryLookupSingle() {
  var map = {'foo': 'bar'};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "foo", powerset: {I}), value: Value([null|exact=JSString|powerset={null}{I}], value: "bar", powerset: {null}{I}), map: {foo: Value([exact=JSString|powerset={I}], value: "bar", powerset: {I})}, powerset: {N})*/
  ['foo'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryLookupMultiple:Value([exact=JSString|powerset={I}], value: "boz", powerset: {I})*/
dictionaryLookupMultiple() {
  var map = {'foo': 'bar', 'baz': 'boz'};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: [null|exact=JSString|powerset={null}{I}], map: {foo: Value([exact=JSString|powerset={I}], value: "bar", powerset: {I}), baz: Value([exact=JSString|powerset={I}], value: "boz", powerset: {I})}, powerset: {N})*/
  ['baz'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with String keys with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryLookupMissing:[null|powerset={null}]*/
dictionaryLookupMissing() {
  var map = {'foo': 'bar', 'baz': 'boz'};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: [null|exact=JSString|powerset={null}{I}], map: {foo: Value([exact=JSString|powerset={I}], value: "bar", powerset: {I}), baz: Value([exact=JSString|powerset={I}], value: "boz", powerset: {I})}, powerset: {N})*/
  ['unknown'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a string-to-int map.
////////////////////////////////////////////////////////////////////////////////

/*member: intDictionaryLookupSingle:[exact=JSUInt31|powerset={I}]*/
intDictionaryLookupSingle() {
  var map = {'foo': 0};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "foo", powerset: {I}), value: [null|exact=JSUInt31|powerset={null}{I}], map: {foo: [exact=JSUInt31|powerset={I}]}, powerset: {N})*/
  ['foo'];
}

////////////////////////////////////////////////////////////////////////////////
// Index access on custom class.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}]*/
class Class1 {
  /*member: Class1.[]:[exact=JSUInt31|powerset={I}]*/
  operator [](/*[exact=JSUInt31|powerset={I}]*/ index) => index;
}

/*member: customIndex:[exact=JSUInt31|powerset={I}]*/
customIndex() => Class1() /*[exact=Class1|powerset={N}]*/ [42];

////////////////////////////////////////////////////////////////////////////////
// Index access on custom class through `this`.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset={N}]*/
class Class2 {
  /*member: Class2.[]:[exact=JSUInt31|powerset={I}]*/
  operator [](/*[exact=JSUInt31|powerset={I}]*/ index) => index;

  /*member: Class2.method:[exact=JSUInt31|powerset={I}]*/
  method() => this /*[exact=Class2|powerset={N}]*/ [42];
}

/*member: customIndexThis:[exact=JSUInt31|powerset={I}]*/
customIndexThis() => Class2(). /*invoke: [exact=Class2|powerset={N}]*/ method();

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
