// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton list.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetSingle:[exact=JSUInt31|powerset={I}{O}]*/
listIndexSetSingle() {
  var list = [0];
  return list
      /*update: Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 1, powerset: {I}{G})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with multiple elements.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetMultiple:[exact=JSUInt31|powerset={I}{O}]*/
listIndexSetMultiple() {
  var list = [0, 1, 2, 3];
  return list
      /*update: Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 4, powerset: {I}{G})*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with an out-of-range index.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetBad:[exact=JSUInt31|powerset={I}{O}]*/
listIndexSetBad() {
  var list = [0, 1];
  return list
      /*update: Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 2, powerset: {I}{G})*/
      [3] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with mixed element types.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetMixed:[exact=JSUInt31|powerset={I}{O}]*/
listIndexSetMixed() {
  dynamic list = [''];
  return list
      /*update: Container([exact=JSExtendableArray|powerset={I}{G}], element: Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O}), length: 1, powerset: {I}{G})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a empty map.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateEmpty:[exact=JSUInt31|powerset={I}{O}]*/
mapUpdateEmpty() {
  var map = {};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSUInt31|powerset={I}{O}], value: [null|exact=JSUInt31|powerset={null}{I}{O}], powerset: {N}{O})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateSingle:[exact=JSUInt31|powerset={I}{O}]*/
mapUpdateSingle() {
  var map = {0: 1};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSUInt31|powerset={I}{O}], value: [null|exact=JSUInt31|powerset={null}{I}{O}], powerset: {N}{O})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with multiple entries.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMultiple:[exact=JSUInt31|powerset={I}{O}]*/
mapUpdateMultiple() {
  var map = {0: 1, 2: 3, 4: 5};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSUInt31|powerset={I}{O}], value: [null|exact=JSUInt31|powerset={null}{I}{O}], powerset: {N}{O})*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMissing:[exact=JSUInt31|powerset={I}{O}]*/
mapUpdateMissing() {
  var map = {0: 1};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSUInt31|powerset={I}{O}], value: [null|exact=JSUInt31|powerset={null}{I}{O}], powerset: {N}{O})*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with mixed key types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMixedKeys:[exact=JSUInt31|powerset={I}{O}]*/
mapUpdateMixedKeys() {
  dynamic map = {'': 2};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: [null|exact=JSUInt31|powerset={null}{I}{O}], powerset: {N}{O})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with mixed value types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMixedValues:[exact=JSUInt31|powerset={I}{O}]*/
mapUpdateMixedValues() {
  dynamic map = {2: ''};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSUInt31|powerset={I}{O}], value: [null|exact=JSString|powerset={null}{I}{O}], powerset: {N}{O})*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to an empty map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateEmpty:Value([exact=JSString|powerset={I}{O}], value: "bar", powerset: {I}{O})*/
dictionaryUpdateEmpty() {
  var map = {};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "foo", powerset: {I}{O}), value: Value([null|exact=JSString|powerset={null}{I}{O}], value: "bar", powerset: {null}{I}{O}), map: {foo: Value([null|exact=JSString|powerset={null}{I}{O}], value: "bar", powerset: {null}{I}{O})}, powerset: {N}{O})*/
      ['foo'] =
      'bar';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map with String keys with a new value.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateSingle:Value([exact=JSString|powerset={I}{O}], value: "boz", powerset: {I}{O})*/
dictionaryUpdateSingle() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "foo", powerset: {I}{O}), value: [null|exact=JSString|powerset={null}{I}{O}], map: {foo: [exact=JSString|powerset={I}{O}]}, powerset: {N}{O})*/
      ['foo'] =
      'boz';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map with String keys with the same value.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryReUpdateSingle:Value([exact=JSString|powerset={I}{O}], value: "bar", powerset: {I}{O})*/
dictionaryReUpdateSingle() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "foo", powerset: {I}{O}), value: Value([null|exact=JSString|powerset={null}{I}{O}], value: "bar", powerset: {null}{I}{O}), map: {foo: Value([exact=JSString|powerset={I}{O}], value: "bar", powerset: {I}{O})}, powerset: {N}{O})*/
      ['foo'] =
      'bar';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateMultiple:Value([exact=JSString|powerset={I}{O}], value: "boz", powerset: {I}{O})*/
dictionaryUpdateMultiple() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: [null|exact=JSString|powerset={null}{I}{O}], map: {foo: Value([exact=JSString|powerset={I}{O}], value: "bar", powerset: {I}{O}), baz: Value([null|exact=JSString|powerset={null}{I}{O}], value: "boz", powerset: {null}{I}{O})}, powerset: {N}{O})*/
      ['baz'] =
      'boz';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a string-to-int map.
////////////////////////////////////////////////////////////////////////////////

/*member: intDictionaryUpdateSingle:[exact=JSUInt31|powerset={I}{O}]*/
intDictionaryUpdateSingle() {
  var map = {};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}{O}], key: Value([exact=JSString|powerset={I}{O}], value: "foo", powerset: {I}{O}), value: [null|exact=JSUInt31|powerset={null}{I}{O}], map: {foo: [null|exact=JSUInt31|powerset={null}{I}{O}]}, powerset: {N}{O})*/
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
