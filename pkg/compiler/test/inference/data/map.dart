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

/*member: emptyMap:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
emptyMap() => {};

/*member: constMap:Dictionary([subclass=ConstantMap|powerset={N}{O}], key: [empty|powerset=empty], value: [null|powerset={null}], map: {}, powerset: {N}{O})*/
constMap() => const {};

/*member: nullMap:Map([subclass=JsLinkedHashMap|powerset={N}{O}], key: [null|powerset={null}], value: [null|powerset={null}], powerset: {N}{O})*/
nullMap() => {null: null};

/*member: constNullMap:Map([subclass=ConstantMap|powerset={N}{O}], key: [null|powerset={null}], value: [null|powerset={null}], powerset: {N}{O})*/
constNullMap() => const {null: null};

/*member: stringIntMap:Dictionary([subclass=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: [null|exact=JSUInt31|powerset={null}{I}{O}], map: {a: [exact=JSUInt31|powerset={I}{O}], b: [exact=JSUInt31|powerset={I}{O}], c: [exact=JSUInt31|powerset={I}{O}]}, powerset: {N}{O})*/
stringIntMap() => {'a': 1, 'b': 2, 'c': 3};

/*member: intStringMap:Map([subclass=JsLinkedHashMap|powerset={N}{O}], key: [exact=JSUInt31|powerset={I}{O}], value: [null|exact=JSString|powerset={null}{I}{O}], powerset: {N}{O})*/
intStringMap() => {1: 'a', 2: 'b', 3: 'c'};

/*member: constStringIntMap:Dictionary([subclass=ConstantMap|powerset={N}{O}], key: [exact=JSString|powerset={I}{O}], value: [null|exact=JSUInt31|powerset={null}{I}{O}], map: {a: [exact=JSUInt31|powerset={I}{O}], b: [exact=JSUInt31|powerset={I}{O}], c: [exact=JSUInt31|powerset={I}{O}]}, powerset: {N}{O})*/
constStringIntMap() => const {'a': 1, 'b': 2, 'c': 3};

/*member: constIntStringMap:Map([subclass=ConstantMap|powerset={N}{O}], key: [exact=JSUInt31|powerset={I}{O}], value: [null|exact=JSString|powerset={null}{I}{O}], powerset: {N}{O})*/
constIntStringMap() => const {1: 'a', 2: 'b', 3: 'c'};
