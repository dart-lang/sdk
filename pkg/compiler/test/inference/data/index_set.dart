// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton list.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetSingle:[exact=JSUInt31]*/
listIndexSetSingle() {
  var list = [0];
  return list
      /*update: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with multiple elements.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetMultiple:[exact=JSUInt31]*/
listIndexSetMultiple() {
  var list = [0, 1, 2, 3];
  return list
      /*update: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 4)*/
      [2] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with an out-of-range index.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetBad:[exact=JSUInt31]*/
listIndexSetBad() {
  var list = [0, 1];
  return list
      /*update: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 2)*/
      [3] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with mixed element types.
////////////////////////////////////////////////////////////////////////////////

/*member: listIndexSetMixed:[exact=JSUInt31]*/
listIndexSetMixed() {
  dynamic list = [''];
  return list
      /*update: Container([exact=JSExtendableArray], element: Union([exact=JSString], [exact=JSUInt31]), length: 1)*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a empty map.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateEmpty:[exact=JSUInt31]*/
mapUpdateEmpty() {
  var map = {};
  return map
      /*update: Map([subclass=JsLinkedHashMap], key: [exact=JSUInt31], value: [null|exact=JSUInt31])*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateSingle:[exact=JSUInt31]*/
mapUpdateSingle() {
  var map = {0: 1};
  return map
      /*update: Map([subclass=JsLinkedHashMap], key: [exact=JSUInt31], value: [null|exact=JSUInt31])*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with multiple entries.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMultiple:[exact=JSUInt31]*/
mapUpdateMultiple() {
  var map = {0: 1, 2: 3, 4: 5};
  return map
      /*update: Map([subclass=JsLinkedHashMap], key: [exact=JSUInt31], value: [null|exact=JSUInt31])*/
      [2] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMissing:[exact=JSUInt31]*/
mapUpdateMissing() {
  var map = {0: 1};
  return map
      /*update: Map([subclass=JsLinkedHashMap], key: [exact=JSUInt31], value: [null|exact=JSUInt31])*/
      [2] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with mixed key types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMixedKeys:[exact=JSUInt31]*/
mapUpdateMixedKeys() {
  dynamic map = {'': 2};
  return map
      /*update: Map([subclass=JsLinkedHashMap], key: Union([exact=JSString], [exact=JSUInt31]), value: [null|exact=JSUInt31])*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with mixed value types.
////////////////////////////////////////////////////////////////////////////////

/*member: mapUpdateMixedValues:[exact=JSUInt31]*/
mapUpdateMixedValues() {
  dynamic map = {2: ''};
  return map
      /*update: Map([subclass=JsLinkedHashMap], key: [exact=JSUInt31], value: Union(null, [exact=JSString], [exact=JSUInt31]))*/
      [2] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to an empty map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateEmpty:Value([exact=JSString], value: "bar")*/
dictionaryUpdateEmpty() {
  var map = {};
  return map
      /*update: Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "foo"), value: Value([null|exact=JSString], value: "bar"), map: {foo: Value([null|exact=JSString], value: "bar")})*/
      ['foo'] = 'bar';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map with String keys with a new value.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateSingle:Value([exact=JSString], value: "boz")*/
dictionaryUpdateSingle() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "foo"), value: [null|exact=JSString], map: {foo: [exact=JSString]})*/
      ['foo'] = 'boz';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map with String keys with the same value.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryReUpdateSingle:Value([exact=JSString], value: "bar")*/
dictionaryReUpdateSingle() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "foo"), value: Value([null|exact=JSString], value: "bar"), map: {foo: Value([exact=JSString], value: "bar")})*/
      ['foo'] = 'bar';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*member: dictionaryUpdateMultiple:Value([exact=JSString], value: "boz")*/
dictionaryUpdateMultiple() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: [null|exact=JSString], map: {foo: Value([exact=JSString], value: "bar"), baz: Value([null|exact=JSString], value: "boz")})*/
      ['baz'] = 'boz';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a string-to-int map.
////////////////////////////////////////////////////////////////////////////////

/*member: intDictionaryUpdateSingle:[exact=JSUInt31]*/
intDictionaryUpdateSingle() {
  var map = {};
  return map
      /*update: Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "foo"), value: [null|exact=JSUInt31], map: {foo: [null|exact=JSUInt31]})*/
      ['foo'] = 0;
}

/*member: main:[null]*/
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
