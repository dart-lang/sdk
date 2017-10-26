// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton list.
////////////////////////////////////////////////////////////////////////////////

/*element: listIndexSingle:[exact=JSUInt31]*/
listIndexSingle() {
  var list = [0];
  return list
      /*invoke: Container mask: [exact=JSUInt31] length: 1 type: [exact=JSExtendableArray]*/
      [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with multiple elements.
////////////////////////////////////////////////////////////////////////////////

/*element: listIndexMultiple:[exact=JSUInt31]*/
listIndexMultiple() {
  var list = [0, 1, 2, 3];
  return list
      /*invoke: Container mask: [exact=JSUInt31] length: 4 type: [exact=JSExtendableArray]*/
      [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with an out-of-range index.
////////////////////////////////////////////////////////////////////////////////

/*element: listIndexBad:[exact=JSUInt31]*/
listIndexBad() {
  var list = [0, 1];
  return list
      /*invoke: Container mask: [exact=JSUInt31] length: 2 type: [exact=JSExtendableArray]*/
      [3];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a list with mixed element types.
////////////////////////////////////////////////////////////////////////////////

/*element: listIndexMixed:Union of [[exact=JSString], [exact=JSUInt31]]*/
listIndexMixed() {
  var list = [0, ''];
  return list
      /*invoke: Container mask: Union of [[exact=JSString], [exact=JSUInt31]] length: 2 type: [exact=JSExtendableArray]*/
      [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton map.
////////////////////////////////////////////////////////////////////////////////

/*element: mapLookupSingle:[null|exact=JSUInt31]*/
mapLookupSingle() {
  var map = {0: 1};
  return map
      /*invoke: Map mask: [[exact=JSUInt31]/[null|exact=JSUInt31]] type: [subclass=JsLinkedHashMap]*/
      [0];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with multiple entries.
////////////////////////////////////////////////////////////////////////////////

/*element: mapLookupMultiple:[null|exact=JSUInt31]*/
mapLookupMultiple() {
  var map = {0: 1, 2: 3, 4: 5};
  return map
      /*invoke: Map mask: [[exact=JSUInt31]/[null|exact=JSUInt31]] type: [subclass=JsLinkedHashMap]*/
      [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*element: mapLookupMissing:[null|exact=JSUInt31]*/
mapLookupMissing() {
  var map = {0: 1};
  return map
      /*invoke: Map mask: [[exact=JSUInt31]/[null|exact=JSUInt31]] type: [subclass=JsLinkedHashMap]*/
      [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with mixed key types.
////////////////////////////////////////////////////////////////////////////////

/*element: mapLookupMixedKeys:[null|exact=JSUInt31]*/
mapLookupMixedKeys() {
  var map = {0: 1, '': 2};
  return map
      /*invoke: Map mask: [Union of [[exact=JSString], [exact=JSUInt31]]/[null|exact=JSUInt31]] type: [subclass=JsLinkedHashMap]*/
      [''];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with mixed value types.
////////////////////////////////////////////////////////////////////////////////

/*element: mapLookupMixedValues:Union of [[exact=JSUInt31], [null|exact=JSString]]*/
mapLookupMixedValues() {
  var map = {0: 1, 2: ''};
  return map
      /*invoke: Map mask: [[exact=JSUInt31]/Union of [[exact=JSUInt31], [null|exact=JSString]]] type: [subclass=JsLinkedHashMap]*/
      [2];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a singleton map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*element: dictionaryLookupSingle:Value mask: ["bar"] type: [exact=JSString]*/
dictionaryLookupSingle() {
  var map = {'foo': 'bar'};
  return map
      /*invoke: Dictionary mask: [Value mask: ["foo"] type: [exact=JSString]/Value mask: ["bar"] type: [null|exact=JSString] with {foo: Value mask: ["bar"] type: [exact=JSString]}] type: [subclass=JsLinkedHashMap]*/
      ['foo'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*element: dictionaryLookupMultiple:Value mask: ["boz"] type: [exact=JSString]*/
dictionaryLookupMultiple() {
  var map = {'foo': 'bar', 'baz': 'boz'};
  return map
      /*invoke: Dictionary mask: [[exact=JSString]/[null|exact=JSString] with {foo: Value mask: ["bar"] type: [exact=JSString], baz: Value mask: ["boz"] type: [exact=JSString]}] type: [subclass=JsLinkedHashMap]*/
      ['baz'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a map with String keys with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*element: dictionaryLookupMissing:[null]*/
dictionaryLookupMissing() {
  var map = {'foo': 'bar', 'baz': 'boz'};
  return map
      /*invoke: Dictionary mask: [[exact=JSString]/[null|exact=JSString] with {foo: Value mask: ["bar"] type: [exact=JSString], baz: Value mask: ["boz"] type: [exact=JSString]}] type: [subclass=JsLinkedHashMap]*/
      ['unknown'];
}

////////////////////////////////////////////////////////////////////////////////
// Lookup into a string-to-int map.
////////////////////////////////////////////////////////////////////////////////

/*element: intDictionaryLookupSingle:[exact=JSUInt31]*/
intDictionaryLookupSingle() {
  var map = {'foo': 0};
  return map
      /*invoke: Dictionary mask: [Value mask: ["foo"] type: [exact=JSString]/[null|exact=JSUInt31] with {foo: [exact=JSUInt31]}] type: [subclass=JsLinkedHashMap]*/
      ['foo'];
}

/*element: main:[null]*/
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
}
