// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: emptyMap:Dictionary([subclass=JsLinkedHashMap|powerset={N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N})*/
emptyMap() => {};

/*member: constMap:Dictionary([subclass=ConstantMap|powerset={N}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N})*/
constMap() => const {};

/*member: nullMap:Map([subclass=JsLinkedHashMap|powerset={N}], key: [null|powerset={null}], value: [null|powerset={null}], powerset: {N})*/
nullMap() => {null: null};

/*member: constNullMap:Map([subclass=ConstantMap|powerset={N}], key: [null|powerset={null}], value: [null|powerset={null}], powerset: {N})*/
constNullMap() => const {null: null};

/*member: stringIntMap:Dictionary([subclass=JsLinkedHashMap|powerset={N}], key: [exact=JSString|powerset={I}], value: [null|exact=JSUInt31|powerset={null}{I}], map: {a: [exact=JSUInt31|powerset={I}], b: [exact=JSUInt31|powerset={I}], c: [exact=JSUInt31|powerset={I}]}, powerset: {N})*/
stringIntMap() => {'a': 1, 'b': 2, 'c': 3};

/*member: intStringMap:Map([subclass=JsLinkedHashMap|powerset={N}], key: [exact=JSUInt31|powerset={I}], value: [null|exact=JSString|powerset={null}{I}], powerset: {N})*/
intStringMap() => {1: 'a', 2: 'b', 3: 'c'};

/*member: constStringIntMap:Dictionary([subclass=ConstantMap|powerset={N}], key: [exact=JSString|powerset={I}], value: [null|exact=JSUInt31|powerset={null}{I}], map: {a: [exact=JSUInt31|powerset={I}], b: [exact=JSUInt31|powerset={I}], c: [exact=JSUInt31|powerset={I}]}, powerset: {N})*/
constStringIntMap() => const {'a': 1, 'b': 2, 'c': 3};

/*member: constIntStringMap:Map([subclass=ConstantMap|powerset={N}], key: [exact=JSUInt31|powerset={I}], value: [null|exact=JSString|powerset={null}{I}], powerset: {N})*/
constIntStringMap() => const {1: 'a', 2: 'b', 3: 'c'};
