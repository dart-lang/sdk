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
      /*invoke: Container mask: [exact=JSUInt31] length: 1 type: [exact=JSExtendableArray]*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with multiple elements.
////////////////////////////////////////////////////////////////////////////////

/*element: listIndexSetMultiple:[exact=JSUInt31]*/
listIndexSetMultiple() {
  var list = [0, 1, 2, 3];
  return list
      /*invoke: Container mask: [exact=JSUInt31] length: 4 type: [exact=JSExtendableArray]*/
      [2] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with an out-of-range index.
////////////////////////////////////////////////////////////////////////////////

/*element: listIndexSetBad:[exact=JSUInt31]*/
listIndexSetBad() {
  var list = [0, 1];
  return list
      /*invoke: Container mask: [exact=JSUInt31] length: 2 type: [exact=JSExtendableArray]*/
      [3] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a list with mixed element types.
////////////////////////////////////////////////////////////////////////////////

/*element: listIndexSetMixed:[exact=JSUInt31]*/
listIndexSetMixed() {
  dynamic list = [''];
  return list
      /*invoke: Container mask: Union of [[exact=JSString], [exact=JSUInt31]] length: 1 type: [exact=JSExtendableArray]*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a empty map.
////////////////////////////////////////////////////////////////////////////////

/*element: mapUpdateEmpty:[exact=JSUInt31]*/
mapUpdateEmpty() {
  var map = {};
  return map
      /*invoke: Map mask: [[exact=JSUInt31]/[null|exact=JSUInt31]] type: [subclass=JsLinkedHashMap]*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map.
////////////////////////////////////////////////////////////////////////////////

/*element: mapUpdateSingle:[exact=JSUInt31]*/
mapUpdateSingle() {
  var map = {0: 1};
  return map
      /*invoke: Map mask: [[exact=JSUInt31]/[null|exact=JSUInt31]] type: [subclass=JsLinkedHashMap]*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with multiple entries.
////////////////////////////////////////////////////////////////////////////////

/*element: mapUpdateMultiple:[exact=JSUInt31]*/
mapUpdateMultiple() {
  var map = {0: 1, 2: 3, 4: 5};
  return map
      /*invoke: Map mask: [[exact=JSUInt31]/[null|exact=JSUInt31]] type: [subclass=JsLinkedHashMap]*/
      [2] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with a missing key.
////////////////////////////////////////////////////////////////////////////////

/*element: mapUpdateMissing:[exact=JSUInt31]*/
mapUpdateMissing() {
  var map = {0: 1};
  return map
      /*invoke: Map mask: [[exact=JSUInt31]/[null|exact=JSUInt31]] type: [subclass=JsLinkedHashMap]*/
      [2] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with mixed key types.
////////////////////////////////////////////////////////////////////////////////

/*element: mapUpdateMixedKeys:[exact=JSUInt31]*/
mapUpdateMixedKeys() {
  dynamic map = {'': 2};
  return map
      /*invoke: Map mask: [Union of [[exact=JSString], [exact=JSUInt31]]/[null|exact=JSUInt31]] type: [subclass=JsLinkedHashMap]*/
      [0] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with mixed value types.
////////////////////////////////////////////////////////////////////////////////

/*element: mapUpdateMixedValues:[exact=JSUInt31]*/
mapUpdateMixedValues() {
  dynamic map = {2: ''};
  return map
      /*invoke: Map mask: [[exact=JSUInt31]/Union of [[exact=JSUInt31], [null|exact=JSString]]] type: [subclass=JsLinkedHashMap]*/
      [2] = 42;
}

////////////////////////////////////////////////////////////////////////////////
// Update to an empty map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*element: dictionaryUpdateEmpty:Value mask: ["bar"] type: [exact=JSString]*/
dictionaryUpdateEmpty() {
  var map = {};
  return map
      /*invoke: Dictionary mask: [Value mask: ["foo"] type: [exact=JSString]/Value mask: ["bar"] type: [null|exact=JSString] with {foo: Value mask: ["bar"] type: [null|exact=JSString]}] type: [subclass=JsLinkedHashMap]*/
      ['foo'] = 'bar';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map with String keys with a new value.
////////////////////////////////////////////////////////////////////////////////

/*element: dictionaryUpdateSingle:Value mask: ["boz"] type: [exact=JSString]*/
dictionaryUpdateSingle() {
  var map = {'foo': 'bar'};
  return map
      /*invoke: Dictionary mask: [Value mask: ["foo"] type: [exact=JSString]/[null|exact=JSString] with {foo: [exact=JSString]}] type: [subclass=JsLinkedHashMap]*/
      ['foo'] = 'boz';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a singleton map with String keys with the same value.
////////////////////////////////////////////////////////////////////////////////

/*element: dictionaryReUpdateSingle:Value mask: ["bar"] type: [exact=JSString]*/
dictionaryReUpdateSingle() {
  var map = {'foo': 'bar'};
  return map
      /*invoke: Dictionary mask: [Value mask: ["foo"] type: [exact=JSString]/Value mask: ["bar"] type: [null|exact=JSString] with {foo: Value mask: ["bar"] type: [exact=JSString]}] type: [subclass=JsLinkedHashMap]*/
      ['foo'] = 'bar';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a map with String keys.
////////////////////////////////////////////////////////////////////////////////

/*element: dictionaryUpdateMultiple:Value mask: ["boz"] type: [exact=JSString]*/
dictionaryUpdateMultiple() {
  var map = {'foo': 'bar'};
  return map
      /*invoke: Dictionary mask: [[exact=JSString]/[null|exact=JSString] with {foo: Value mask: ["bar"] type: [exact=JSString], baz: Value mask: ["boz"] type: [null|exact=JSString]}] type: [subclass=JsLinkedHashMap]*/
      ['baz'] = 'boz';
}

////////////////////////////////////////////////////////////////////////////////
// Update to a string-to-int map.
////////////////////////////////////////////////////////////////////////////////

/*element: intDictionaryUpdateSingle:[exact=JSUInt31]*/
intDictionaryUpdateSingle() {
  var map = {};
  return map
      /*invoke: Dictionary mask: [Value mask: ["foo"] type: [exact=JSString]/[null|exact=JSUInt31] with {foo: [null|exact=JSUInt31]}] type: [subclass=JsLinkedHashMap]*/
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
