// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton list.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetSingle:[exact=JSUInt31|powerset=0]*/
listIndexSetSingle() {
  var list = [0];
  return list
      /*update: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with multiple elements.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetMultiple:[exact=JSUInt31|powerset=0]*/
listIndexSetMultiple() {
  var list = [0, 1, 2, 3];
  return list
      /*update: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 4, powerset: 0)*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with an out-of-range index.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetBad:[exact=JSUInt31|powerset=0]*/
listIndexSetBad() {
  var list = [0, 1];
  return list
      /*update: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 2, powerset: 0)*/
      [3] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with mixed element types.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetMixed:[exact=JSUInt31|powerset=0]*/
listIndexSetMixed() {
  dynamic list = [''];
  return list
      /*update: Container([exact=JSExtendableArray|powerset=0], element: Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), length: 1, powerset: 0)*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a empty map.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateEmpty:[exact=JSUInt31|powerset=0]*/
mapUpdateEmpty() {
  var map = {};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset=0], key: [exact=JSUInt31|powerset=0], value: [null|exact=JSUInt31|powerset=1], powerset: 0)*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateSingle:[exact=JSUInt31|powerset=0]*/
mapUpdateSingle() {
  var map = {0: 1};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset=0], key: [exact=JSUInt31|powerset=0], value: [null|exact=JSUInt31|powerset=1], powerset: 0)*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with multiple entries.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMultiple:[exact=JSUInt31|powerset=0]*/
mapUpdateMultiple() {
  var map = {0: 1, 2: 3, 4: 5};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset=0], key: [exact=JSUInt31|powerset=0], value: [null|exact=JSUInt31|powerset=1], powerset: 0)*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMissing:[exact=JSUInt31|powerset=0]*/
mapUpdateMissing() {
  var map = {0: 1};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset=0], key: [exact=JSUInt31|powerset=0], value: [null|exact=JSUInt31|powerset=1], powerset: 0)*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with mixed key types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMixedKeys:[exact=JSUInt31|powerset=0]*/
mapUpdateMixedKeys() {
  dynamic map = {'': 2};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|exact=JSUInt31|powerset=1], powerset: 0)*/
      [0] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with mixed value types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMixedValues:[exact=JSUInt31|powerset=0]*/
mapUpdateMixedValues() {
  dynamic map = {2: ''};
  return map
      /*update: Map([exact=JsLinkedHashMap|powerset=0], key: [exact=JSUInt31|powerset=0], value: [null|exact=JSString|powerset=1], powerset: 0)*/
      [2] =
      42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to an empty map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateEmpty:Value([exact=JSString|powerset=0], value: "bar", powerset: 0)*/
dictionaryUpdateEmpty() {
  var map = {};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "foo", powerset: 0), value: Value([null|exact=JSString|powerset=1], value: "bar", powerset: 1), map: {foo: Value([null|exact=JSString|powerset=1], value: "bar", powerset: 1)}, powerset: 0)*/
      ['foo'] =
      'bar';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map with String keys with a new value.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateSingle:Value([exact=JSString|powerset=0], value: "boz", powerset: 0)*/
dictionaryUpdateSingle() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "foo", powerset: 0), value: [null|exact=JSString|powerset=1], map: {foo: [exact=JSString|powerset=0]}, powerset: 0)*/
      ['foo'] =
      'boz';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map with String keys with the same value.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryReUpdateSingle:Value([exact=JSString|powerset=0], value: "bar", powerset: 0)*/
dictionaryReUpdateSingle() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "foo", powerset: 0), value: Value([null|exact=JSString|powerset=1], value: "bar", powerset: 1), map: {foo: Value([exact=JSString|powerset=0], value: "bar", powerset: 0)}, powerset: 0)*/
      ['foo'] =
      'bar';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateMultiple:Value([exact=JSString|powerset=0], value: "boz", powerset: 0)*/
dictionaryUpdateMultiple() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|exact=JSString|powerset=1], map: {foo: Value([exact=JSString|powerset=0], value: "bar", powerset: 0), baz: Value([null|exact=JSString|powerset=1], value: "boz", powerset: 1)}, powerset: 0)*/
      ['baz'] =
      'boz';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a string-to-int map.
////////////////////////////////////////////////////////////////////////////////

/*member: intDictionaryUpdateSingle:[exact=JSUInt31|powerset=0]*/
intDictionaryUpdateSingle() {
  var map = {};
  return map
      /*update: Dictionary([exact=JsLinkedHashMap|powerset=0], key: Value([exact=JSString|powerset=0], value: "foo", powerset: 0), value: [null|exact=JSUInt31|powerset=1], map: {foo: [null|exact=JSUInt31|powerset=1]}, powerset: 0)*/
      ['foo'] =
      0;
}

/*member: main:[null|powerset=1]*/
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
