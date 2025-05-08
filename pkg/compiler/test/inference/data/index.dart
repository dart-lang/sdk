// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton list.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSingle:[exact=JSUInt31|powerset={I}{O}{N}]*/
listIndexSingle() {
  var list = [0];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
  [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with multiple elements.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexMultiple:[exact=JSUInt31|powerset={I}{O}{N}]*/
listIndexMultiple() {
  var list = [0, 1, 2, 3];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 4, powerset: {I}{G}{M})*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with an out-of-range index.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexBad:[exact=JSUInt31|powerset={I}{O}{N}]*/
listIndexBad() {
  var list = [0, 1];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M})*/
  [3];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with mixed element types.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexMixed:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
listIndexMixed() {
  var list = [0, ''];
  return list
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN}), length: 2, powerset: {I}{G}{M})*/
  [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton map.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupSingle:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
mapLookupSingle() {
  var map = {0: 1};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSUInt31|powerset={I}{O}{N}], value: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], powerset: {N}{O}{N})*/
  [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with multiple entries.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMultiple:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
mapLookupMultiple() {
  var map = {0: 1, 2: 3, 4: 5};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSUInt31|powerset={I}{O}{N}], value: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], powerset: {N}{O}{N})*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMissing:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
mapLookupMissing() {
  var map = {0: 1};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSUInt31|powerset={I}{O}{N}], value: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], powerset: {N}{O}{N})*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with mixed key types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMixedKeys:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
mapLookupMixedKeys() {
  var map = {0: 1, '': 2};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN}), value: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], powerset: {N}{O}{N})*/
  [''];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with mixed value types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMixedValues:Union(null, [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN})*/
mapLookupMixedValues() {
  var map = {0: 1, 2: ''};
  return map
  /*Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSUInt31|powerset={I}{O}{N}], value: Union(null, [exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {null}{I}{O}{IN}), powerset: {N}{O}{N})*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryLookupSingle:Value([exact=JSString|powerset={I}{O}{I}], value: "bar", powerset: {I}{O}{I})*/
dictionaryLookupSingle() {
  var map = {'foo': 'bar'};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "foo", powerset: {I}{O}{I}), value: Value([null|exact=JSString|powerset={null}{I}{O}{I}], value: "bar", powerset: {null}{I}{O}{I}), map: {foo: Value([exact=JSString|powerset={I}{O}{I}], value: "bar", powerset: {I}{O}{I})}, powerset: {N}{O}{N})*/
  ['foo'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryLookupMultiple:Value([exact=JSString|powerset={I}{O}{I}], value: "boz", powerset: {I}{O}{I})*/
dictionaryLookupMultiple() {
  var map = {'foo': 'bar', 'baz': 'boz'};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|exact=JSString|powerset={null}{I}{O}{I}], map: {foo: Value([exact=JSString|powerset={I}{O}{I}], value: "bar", powerset: {I}{O}{I}), baz: Value([exact=JSString|powerset={I}{O}{I}], value: "boz", powerset: {I}{O}{I})}, powerset: {N}{O}{N})*/
  ['baz'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with String keys with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryLookupMissing:[null|powerset={null}]*/
dictionaryLookupMissing() {
  var map = {'foo': 'bar', 'baz': 'boz'};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|exact=JSString|powerset={null}{I}{O}{I}], map: {foo: Value([exact=JSString|powerset={I}{O}{I}], value: "bar", powerset: {I}{O}{I}), baz: Value([exact=JSString|powerset={I}{O}{I}], value: "boz", powerset: {I}{O}{I})}, powerset: {N}{O}{N})*/
  ['unknown'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a string-to-int map.
////////////////////////////////////////////////////////////////////////////////

/*member: intDictionaryLookupSingle:[exact=JSUInt31|powerset={I}{O}{N}]*/
intDictionaryLookupSingle() {
  var map = {'foo': 0};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "foo", powerset: {I}{O}{I}), value: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], map: {foo: [exact=JSUInt31|powerset={I}{O}{N}]}, powerset: {N}{O}{N})*/
  ['foo'];
}

////////////////////////////////////////////////////////////////////////////////
// Index access on custom class.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
class Class1 {
  /*member: Class1.[]:[exact=JSUInt31|powerset={I}{O}{N}]*/
  operator [](/*[exact=JSUInt31|powerset={I}{O}{N}]*/ index) => index;
}

/*member: customIndex:[exact=JSUInt31|powerset={I}{O}{N}]*/
customIndex() => Class1() /*[exact=Class1|powerset={N}{O}{N}]*/ [42];

////////////////////////////////////////////////////////////////////////////////
// Index access on custom class through `this`.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset={N}{O}{N}]*/
class Class2 {
  /*member: Class2.[]:[exact=JSUInt31|powerset={I}{O}{N}]*/
  operator [](/*[exact=JSUInt31|powerset={I}{O}{N}]*/ index) => index;

  /*member: Class2.method:[exact=JSUInt31|powerset={I}{O}{N}]*/
  method() => this /*[exact=Class2|powerset={N}{O}{N}]*/ [42];
}

/*member: customIndexThis:[exact=JSUInt31|powerset={I}{O}{N}]*/
customIndexThis() =>
    Class2(). /*invoke: [exact=Class2|powerset={N}{O}{N}]*/ method();

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
