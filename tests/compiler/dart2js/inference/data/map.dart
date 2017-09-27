// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  emptyMap();
  nullMap();
  constMap();
  constNullMap();
  stringIntMap();
  intStringMap();
  constStringIntMap();
  constIntStringMap();
}

/*element: emptyMap:Dictionary mask: [[empty]/[null] with {}] type: [subclass=JsLinkedHashMap]*/
emptyMap() => {};

/*element: constMap:Dictionary mask: [[empty]/[null] with {}] type: [subclass=ConstantMap]*/
constMap() => const {};

/*element: nullMap:Map mask: [[null]/[null]] type: [subclass=JsLinkedHashMap]*/
nullMap() => {null: null};

/*element: constNullMap:Map mask: [[null]/[null]] type: [subclass=ConstantMap]*/
constNullMap() => const {null: null};

/*element: stringIntMap:Dictionary mask: [[exact=JSString]/[null|exact=JSUInt31] with {a: [exact=JSUInt31], b: [exact=JSUInt31], c: [exact=JSUInt31]}] type: [subclass=JsLinkedHashMap]*/
stringIntMap() => {'a': 1, 'b': 2, 'c': 3};

/*element: intStringMap:Map mask: [[exact=JSUInt31]/[null|exact=JSString]] type: [subclass=JsLinkedHashMap]*/
intStringMap() => {1: 'a', 2: 'b', 3: 'c'};

/*element: constStringIntMap:Dictionary mask: [[exact=JSString]/[null|exact=JSUInt31] with {a: [exact=JSUInt31], b: [exact=JSUInt31], c: [exact=JSUInt31]}] type: [subclass=ConstantMap]*/
constStringIntMap() => const {'a': 1, 'b': 2, 'c': 3};

/*element: constIntStringMap:Map mask: [[exact=JSUInt31]/[null|exact=JSString]] type: [subclass=ConstantMap]*/
constIntStringMap() => const {1: 'a', 2: 'b', 3: 'c'};
