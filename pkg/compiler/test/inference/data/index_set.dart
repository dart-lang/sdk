// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton list.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetSingle:[exact=JSUInt31|powerset={I}{O}{N}]*/
listIndexSetSingle() {
  var list = [0];
  return list
      /*update: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 1, powerset: {I}{G}{M})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with multiple elements.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetMultiple:[exact=JSUInt31|powerset={I}{O}{N}]*/
listIndexSetMultiple() {
  var list = [0, 1, 2, 3];
  return list
      /*update: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 4, powerset: {I}{G}{M})*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with an out-of-range index.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetBad:[exact=JSUInt31|powerset={I}{O}{N}]*/
listIndexSetBad() {
  var list = [0, 1];
  return list
      /*update: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M})*/
      [3] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with mixed element types.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetMixed:[exact=JSUInt31|powerset={I}{O}{N}]*/
listIndexSetMixed() {
  dynamic list = [''];
  return list
      /*update: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN}), length: 1, powerset: {I}{G}{M})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a empty map.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateEmpty:[exact=JSUInt31|powerset={I}{O}{N}]*/
mapUpdateEmpty() {
  var map = {};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSUInt31|powerset={I}{O}{N}], value: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], powerset: {N}{O}{N})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateSingle:[exact=JSUInt31|powerset={I}{O}{N}]*/
mapUpdateSingle() {
  var map = {0: 1};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSUInt31|powerset={I}{O}{N}], value: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], powerset: {N}{O}{N})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with multiple entries.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMultiple:[exact=JSUInt31|powerset={I}{O}{N}]*/
mapUpdateMultiple() {
  var map = {0: 1, 2: 3, 4: 5};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSUInt31|powerset={I}{O}{N}], value: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], powerset: {N}{O}{N})*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMissing:[exact=JSUInt31|powerset={I}{O}{N}]*/
mapUpdateMissing() {
  var map = {0: 1};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSUInt31|powerset={I}{O}{N}], value: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], powerset: {N}{O}{N})*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with mixed key types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMixedKeys:[exact=JSUInt31|powerset={I}{O}{N}]*/
mapUpdateMixedKeys() {
  dynamic map = {'': 2};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], powerset: {N}{O}{N})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with mixed value types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMixedValues:[exact=JSUInt31|powerset={I}{O}{N}]*/
mapUpdateMixedValues() {
  dynamic map = {2: ''};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSUInt31|powerset={I}{O}{N}], value: [null|exact=JSString|powerset={null}{I}{O}{I}], powerset: {N}{O}{N})*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to an empty map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateEmpty:Value([exact=JSString|powerset={I}{O}{I}], value: "bar", powerset: {I}{O}{I})*/
dictionaryUpdateEmpty() {
  var map = {};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "foo", powerset: {I}{O}{I}), value: Value([null|exact=JSString|powerset={null}{I}{O}{I}], value: "bar", powerset: {null}{I}{O}{I}), map: {foo: Value([null|exact=JSString|powerset={null}{I}{O}{I}], value: "bar", powerset: {null}{I}{O}{I})}, powerset: {N}{O}{N})*/
      ['foo'] =
      'bar';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map with String keys with a new value.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateSingle:Value([exact=JSString|powerset={I}{O}{I}], value: "boz", powerset: {I}{O}{I})*/
dictionaryUpdateSingle() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "foo", powerset: {I}{O}{I}), value: [null|exact=JSString|powerset={null}{I}{O}{I}], map: {foo: [exact=JSString|powerset={I}{O}{I}]}, powerset: {N}{O}{N})*/
      ['foo'] =
      'boz';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map with String keys with the same value.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryReUpdateSingle:Value([exact=JSString|powerset={I}{O}{I}], value: "bar", powerset: {I}{O}{I})*/
dictionaryReUpdateSingle() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "foo", powerset: {I}{O}{I}), value: Value([null|exact=JSString|powerset={null}{I}{O}{I}], value: "bar", powerset: {null}{I}{O}{I}), map: {foo: Value([exact=JSString|powerset={I}{O}{I}], value: "bar", powerset: {I}{O}{I})}, powerset: {N}{O}{N})*/
      ['foo'] =
      'bar';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateMultiple:Value([exact=JSString|powerset={I}{O}{I}], value: "boz", powerset: {I}{O}{I})*/
dictionaryUpdateMultiple() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: [exact=JSString|powerset={I}{O}{I}], value: [null|exact=JSString|powerset={null}{I}{O}{I}], map: {foo: Value([exact=JSString|powerset={I}{O}{I}], value: "bar", powerset: {I}{O}{I}), baz: Value([null|exact=JSString|powerset={null}{I}{O}{I}], value: "boz", powerset: {null}{I}{O}{I})}, powerset: {N}{O}{N})*/
      ['baz'] =
      'boz';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a string-to-int map.
////////////////////////////////////////////////////////////////////////////////

/*member: intDictionaryUpdateSingle:[exact=JSUInt31|powerset={I}{O}{N}]*/
intDictionaryUpdateSingle() {
  var map = {};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}{N}], key: Value([exact=JSString|powerset={I}{O}{I}], value: "foo", powerset: {I}{O}{I}), value: [null|exact=JSUInt31|powerset={null}{I}{O}{N}], map: {foo: [null|exact=JSUInt31|powerset={null}{I}{O}{N}]}, powerset: {N}{O}{N})*/
      ['foo'] =
      0;
}

/*member: main:[null|powerset={null}]*/
main() {
  listIndexSetSingle();
  listIndexSetMultiple();
  listIndexSetBad();
  listIndexSetMixed();

  mapUpdateEmpty();
  mapUpdateSingle();
  mapUpdateMultiple();
  mapUpdateMissing();
  mapUpdateMixedKeys();
  mapUpdateMixedValues();

  dictionaryUpdateEmpty();
  dictionaryUpdateSingle();
  dictionaryReUpdateSingle();
  dictionaryUpdateMultiple();

  intDictionaryUpdateSingle();
}
