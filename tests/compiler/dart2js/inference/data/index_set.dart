// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton list.
////////////////////////////////////////////////////////////////////////////////

/*element: listIndexSetSingle:[exact=JSUInt31]*/
listIndexSetSingle() {
  var list = [0];
  return list
      /*update: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with multiple elements.
////////////////////////////////////////////////////////////////////////////////

/*element: listIndexSetMultiple:[exact=JSUInt31]*/
listIndexSetMultiple() {
  var list = [0, 1, 2, 3];
  return list
      /*update: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 4)*/
      [2] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with an out-of-range index.
////////////////////////////////////////////////////////////////////////////////

/*element: listIndexSetBad:[exact=JSUInt31]*/
listIndexSetBad() {
  var list = [0, 1];
  return list
      /*update: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 2)*/
      [3] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with mixed element types.
////////////////////////////////////////////////////////////////////////////////

/*element: listIndexSetMixed:[exact=JSUInt31]*/
listIndexSetMixed() {
  dynamic list = [''];
  return list
      /*update: Container([exact=JSExtendableArray], element: Union([exact=JSString], [exact=JSUInt31]), length: 1)*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a empty map.
////////////////////////////////////////////////////////////////////////////////

/*element: mapUpdateEmpty:[exact=JSUInt31]*/
mapUpdateEmpty() {
  var map = {};
  return map
      /*update: Map([subclass=JsLinkedHashMap], key: [exact=JSUInt31], value: [null|exact=JSUInt31])*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map.
////////////////////////////////////////////////////////////////////////////////

/*element: mapUpdateSingle:[exact=JSUInt31]*/
mapUpdateSingle() {
  var map = {0: 1};
  return map
      /*update: Map([subclass=JsLinkedHashMap], key: [exact=JSUInt31], value: [null|exact=JSUInt31])*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with multiple entries.
////////////////////////////////////////////////////////////////////////////////

/*element: mapUpdateMultiple:[exact=JSUInt31]*/
mapUpdateMultiple() {
  var map = {0: 1, 2: 3, 4: 5};
  return map
      /*update: Map([subclass=JsLinkedHashMap], key: [exact=JSUInt31], value: [null|exact=JSUInt31])*/
      [2] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*element: mapUpdateMissing:[exact=JSUInt31]*/
mapUpdateMissing() {
  var map = {0: 1};
  return map
      /*update: Map([subclass=JsLinkedHashMap], key: [exact=JSUInt31], value: [null|exact=JSUInt31])*/
      [2] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with mixed key types.
////////////////////////////////////////////////////////////////////////////////

/*element: mapUpdateMixedKeys:[exact=JSUInt31]*/
mapUpdateMixedKeys() {
  dynamic map = {'': 2};
  return map
      /*update: Map([subclass=JsLinkedHashMap], key: Union([exact=JSString], [exact=JSUInt31]), value: [null|exact=JSUInt31])*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with mixed value types.
////////////////////////////////////////////////////////////////////////////////

/*element: mapUpdateMixedValues:[exact=JSUInt31]*/
mapUpdateMixedValues() {
  dynamic map = {2: ''};
  return map
      /*update: Map([subclass=JsLinkedHashMap], key: [exact=JSUInt31], value: Union([exact=JSUInt31], [null|exact=JSString]))*/
      [2] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to an empty map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*element: dictionaryUpdateEmpty:Value([exact=JSString], value: "bar")*/
dictionaryUpdateEmpty() {
  var map = {};
  return map
      /*update: Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "foo"), value: Value([null|exact=JSString], value: "bar"), map: {foo: Value([null|exact=JSString], value: "bar")})*/
      ['foo'] = 'bar';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map with String keys with a new value.
////////////////////////////////////////////////////////////////////////////////

/*element: dictionaryUpdateSingle:Value([exact=JSString], value: "boz")*/
dictionaryUpdateSingle() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "foo"), value: [null|exact=JSString], map: {foo: [exact=JSString]})*/
      ['foo'] = 'boz';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map with String keys with the same value.
////////////////////////////////////////////////////////////////////////////////

/*element: dictionaryReUpdateSingle:Value([exact=JSString], value: "bar")*/
dictionaryReUpdateSingle() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "foo"), value: Value([null|exact=JSString], value: "bar"), map: {foo: Value([exact=JSString], value: "bar")})*/
      ['foo'] = 'bar';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*element: dictionaryUpdateMultiple:Value([exact=JSString], value: "boz")*/
dictionaryUpdateMultiple() {
  var map = {'foo': 'bar'};
  return map
      /*update: Dictionary([subclass=JsLinkedHashMap], key: [exact=JSString], value: [null|exact=JSString], map: {foo: Value([exact=JSString], value: "bar"), baz: Value([null|exact=JSString], value: "boz")})*/
      ['baz'] = 'boz';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a string-to-int map.
////////////////////////////////////////////////////////////////////////////////

/*element: intDictionaryUpdateSingle:[exact=JSUInt31]*/
intDictionaryUpdateSingle() {
  var map = {};
  return map
      /*update: Dictionary([subclass=JsLinkedHashMap], key: Value([exact=JSString], value: "foo"), value: [null|exact=JSUInt31], map: {foo: [null|exact=JSUInt31]})*/
      ['foo'] = 0;
}

/*element: main:[null]*/
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
