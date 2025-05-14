// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton list.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSingle:[exact=JSUInt31|powerset=0]*/
listIndexSingle() {
  var list = [0];
  return list
  /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
  [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with multiple elements.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexMultiple:[exact=JSUInt31|powerset=0]*/
listIndexMultiple() {
  var list = [0, 1, 2, 3];
  return list
  /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 4, powerset: 0)*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with an out-of-range index.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexBad:[exact=JSUInt31|powerset=0]*/
listIndexBad() {
  var list = [0, 1];
  return list
  /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 2, powerset: 0)*/
  [3];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with mixed element types.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexMixed:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
listIndexMixed() {
  var list = [0, ''];
  return list
  /*Container([exact=JSExtendableArray|powerset=0], element: Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), length: 2, powerset: 0)*/
  [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton map.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupSingle:[null|exact=JSUInt31|powerset=1]*/
mapLookupSingle() {
  var map = {0: 1};
  return map
  /*Map([exact=JsLinkedHashMap|powerset=0], key: [exact=JSUInt31|powerset=0], value: [null|exact=JSUInt31|powerset=1], powerset: 0)*/
  [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with multiple entries.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMultiple:[null|exact=JSUInt31|powerset=1]*/
mapLookupMultiple() {
  var map = {0: 1, 2: 3, 4: 5};
  return map
  /*Map([exact=JsLinkedHashMap|powerset=0], key: [exact=JSUInt31|powerset=0], value: [null|exact=JSUInt31|powerset=1], powerset: 0)*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMissing:[null|exact=JSUInt31|powerset=1]*/
mapLookupMissing() {
  var map = {0: 1};
  return map
  /*Map([exact=JsLinkedHashMap|powerset=0], key: [exact=JSUInt31|powerset=0], value: [null|exact=JSUInt31|powerset=1], powerset: 0)*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with mixed key types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMixedKeys:[null|exact=JSUInt31|powerset=1]*/
mapLookupMixedKeys() {
  var map = {0: 1, '': 2};
  return map
  /*Map([exact=JsLinkedHashMap|powerset=0], key: Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), value: [null|exact=JSUInt31|powerset=1], powerset: 0)*/
  [''];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with mixed value types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapLookupMixedValues:Union(null, [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1)*/
mapLookupMixedValues() {
  var map = {0: 1, 2: ''};
  return map
  /*Map([exact=JsLinkedHashMap|powerset=0], key: [exact=JSUInt31|powerset=0], value: Union(null, [exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 1), powerset: 0)*/
  [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryLookupSingle:Value([exact=JSString|powerset=0], value: "bar", powerset: 0)*/
dictionaryLookupSingle() {
  var map = {'foo': 'bar'};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "foo", powerset: 0), value: Value([null|exact=JSString|powerset=1], value: "bar", powerset: 1), map: {foo: Value([exact=JSString|powerset=0], value: "bar", powerset: 0)}, powerset: 0)*/
  ['foo'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryLookupMultiple:Value([exact=JSString|powerset=0], value: "boz", powerset: 0)*/
dictionaryLookupMultiple() {
  var map = {'foo': 'bar', 'baz': 'boz'};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|exact=JSString|powerset=1], map: {foo: Value([exact=JSString|powerset=0], value: "bar", powerset: 0), baz: Value([exact=JSString|powerset=0], value: "boz", powerset: 0)}, powerset: 0)*/
  ['baz'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with String keys with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryLookupMissing:[null|powerset=1]*/
dictionaryLookupMissing() {
  var map = {'foo': 'bar', 'baz': 'boz'};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|exact=JSString|powerset=1], map: {foo: Value([exact=JSString|powerset=0], value: "bar", powerset: 0), baz: Value([exact=JSString|powerset=0], value: "boz", powerset: 0)}, powerset: 0)*/
  ['unknown'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a string-to-int map.
////////////////////////////////////////////////////////////////////////////////

/*member: intDictionaryLookupSingle:[exact=JSUInt31|powerset=0]*/
intDictionaryLookupSingle() {
  var map = {'foo': 0};
  return map
  /*Dictionary([exact=JsLinkedHashMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "foo", powerset: 0), value: [null|exact=JSUInt31|powerset=1], map: {foo: [exact=JSUInt31|powerset=0]}, powerset: 0)*/
  ['foo'];
}

////////////////////////////////////////////////////////////////////////////////
// Index access on custom class.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset=0]*/
class Class1 {
  /*member: Class1.[]:[exact=JSUInt31|powerset=0]*/
  operator [](/*[exact=JSUInt31|powerset=0]*/ index) => index;
}

/*member: customIndex:[exact=JSUInt31|powerset=0]*/
customIndex() => Class1() /*[exact=Class1|powerset=0]*/ [42];

////////////////////////////////////////////////////////////////////////////////
// Index access on custom class through `this`.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2.:[exact=Class2|powerset=0]*/
class Class2 {
  /*member: Class2.[]:[exact=JSUInt31|powerset=0]*/
  operator [](/*[exact=JSUInt31|powerset=0]*/ index) => index;

  /*member: Class2.method:[exact=JSUInt31|powerset=0]*/
  method() => this /*[exact=Class2|powerset=0]*/ [42];
}

/*member: customIndexThis:[exact=JSUInt31|powerset=0]*/
customIndexThis() => Class2(). /*invoke: [exact=Class2|powerset=0]*/ method();

/*member: main:[null|powerset=1]*/
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
