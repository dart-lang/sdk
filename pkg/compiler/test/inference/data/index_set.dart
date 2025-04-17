// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton list.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetSingle:[exact=JSUInt31|powerset={I}]*/
listIndexSetSingle() {
  var list = [0];
  return list
      /*update: Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 1, powerset: {I})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with multiple elements.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetMultiple:[exact=JSUInt31|powerset={I}]*/
listIndexSetMultiple() {
  var list = [0, 1, 2, 3];
  return list
      /*update: Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 4, powerset: {I})*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with an out-of-range index.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetBad:[exact=JSUInt31|powerset={I}]*/
listIndexSetBad() {
  var list = [0, 1];
  return list
      /*update: Container([exact=JSExtendableArray|powerset={I}], element: [exact=JSUInt31|powerset={I}], length: 2, powerset: {I})*/
      [3] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with mixed element types.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetMixed:[exact=JSUInt31|powerset={I}]*/
listIndexSetMixed() {
  dynamic list = [''];
  return list
      /*update: Container([exact=JSExtendableArray|powerset={I}], element: Union([exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I}), length: 1, powerset: {I})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a empty map.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateEmpty:[exact=JSUInt31|powerset={I}]*/
mapUpdateEmpty() {
  var map = {};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSUInt31|powerset={I}], value: [null|exact=JSUInt31|powerset={null}{I}], powerset: {N})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateSingle:[exact=JSUInt31|powerset={I}]*/
mapUpdateSingle() {
  var map = {0: 1};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSUInt31|powerset={I}], value: [null|exact=JSUInt31|powerset={null}{I}], powerset: {N})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with multiple entries.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMultiple:[exact=JSUInt31|powerset={I}]*/
mapUpdateMultiple() {
  var map = {0: 1, 2: 3, 4: 5};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSUInt31|powerset={I}], value: [null|exact=JSUInt31|powerset={null}{I}], powerset: {N})*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMissing:[exact=JSUInt31|powerset={I}]*/
mapUpdateMissing() {
  var map = {0: 1};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSUInt31|powerset={I}], value: [null|exact=JSUInt31|powerset={null}{I}], powerset: {N})*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with mixed key types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMixedKeys:[exact=JSUInt31|powerset={I}]*/
mapUpdateMixedKeys() {
  dynamic map = {'': 2};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: [null|exact=JSUInt31|powerset={null}{I}], powerset: {N})*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with mixed value types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMixedValues:[exact=JSUInt31|powerset={I}]*/
mapUpdateMixedValues() {
  dynamic map = {2: ''};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSUInt31|powerset={I}], value: [null|exact=JSString|powerset={null}{I}], powerset: {N})*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to an empty map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateEmpty:Value([exact=JSString|powerset={I}], value: "bar", powerset: {I})*/
dictionaryUpdateEmpty() {
  var map = {};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "foo", powerset: {I}), value: Value([null|exact=JSString|powerset={null}{I}], value: "bar", powerset: {null}{I}), map: {foo: Value([null|exact=JSString|powerset={null}{I}], value: "bar", powerset: {null}{I})}, powerset: {N})*/
      ['foo'] =
      'bar';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map with String keys with a new value.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateSingle:Value([exact=JSString|powerset={I}], value: "boz", powerset: {I})*/
dictionaryUpdateSingle() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "foo", powerset: {I}), value: [null|exact=JSString|powerset={null}{I}], map: {foo: [exact=JSString|powerset={I}]}, powerset: {N})*/
      ['foo'] =
      'boz';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map with String keys with the same value.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryReUpdateSingle:Value([exact=JSString|powerset={I}], value: "bar", powerset: {I})*/
dictionaryReUpdateSingle() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "foo", powerset: {I}), value: Value([null|exact=JSString|powerset={null}{I}], value: "bar", powerset: {null}{I}), map: {foo: Value([exact=JSString|powerset={I}], value: "bar", powerset: {I})}, powerset: {N})*/
      ['foo'] =
      'bar';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateMultiple:Value([exact=JSString|powerset={I}], value: "boz", powerset: {I})*/
dictionaryUpdateMultiple() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: [null|exact=JSString|powerset={null}{I}], map: {foo: Value([exact=JSString|powerset={I}], value: "bar", powerset: {I}), baz: Value([null|exact=JSString|powerset={null}{I}], value: "boz", powerset: {null}{I})}, powerset: {N})*/
      ['baz'] =
      'boz';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a string-to-int map.
////////////////////////////////////////////////////////////////////////////////

/*member: intDictionaryUpdateSingle:[exact=JSUInt31|powerset={I}]*/
intDictionaryUpdateSingle() {
  var map = {};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset={N}], key: Value([exact=JSString|powerset={I}], value: "foo", powerset: {I}), value: [null|exact=JSUInt31|powerset={null}{I}], map: {foo: [null|exact=JSUInt31|powerset={null}{I}]}, powerset: {N})*/
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
