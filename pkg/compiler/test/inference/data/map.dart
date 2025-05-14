// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
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

/*member: emptyMap:Dictionary([subclass=JsLinkedHashMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
emptyMap() => {};

/*member: constMap:Dictionary([subclass=ConstantMap|powerset=0], key: [empty|powerset=0], value: [null|powerset=1], map: {}, powerset: 0)*/
constMap() => const {};

/*member: nullMap:Map([subclass=JsLinkedHashMap|powerset=0], key: [null|powerset=1], value: [null|powerset=1], powerset: 0)*/
nullMap() => {null: null};

/*member: constNullMap:Map([subclass=ConstantMap|powerset=0], key: [null|powerset=1], value: [null|powerset=1], powerset: 0)*/
constNullMap() => const {null: null};

/*member: stringIntMap:Dictionary([subclass=JsLinkedHashMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|exact=JSUInt31|powerset=1], map: {a: [exact=JSUInt31|powerset=0], b: [exact=JSUInt31|powerset=0], c: [exact=JSUInt31|powerset=0]}, powerset: 0)*/
stringIntMap() => {'a': 1, 'b': 2, 'c': 3};

/*member: intStringMap:Map([subclass=JsLinkedHashMap|powerset=0], key: [exact=JSUInt31|powerset=0], value: [null|exact=JSString|powerset=1], powerset: 0)*/
intStringMap() => {1: 'a', 2: 'b', 3: 'c'};

/*member: constStringIntMap:Dictionary([subclass=ConstantMap|powerset=0], key: [exact=JSString|powerset=0], value: [null|exact=JSUInt31|powerset=1], map: {a: [exact=JSUInt31|powerset=0], b: [exact=JSUInt31|powerset=0], c: [exact=JSUInt31|powerset=0]}, powerset: 0)*/
constStringIntMap() => const {'a': 1, 'b': 2, 'c': 3};

/*member: constIntStringMap:Map([subclass=ConstantMap|powerset=0], key: [exact=JSUInt31|powerset=0], value: [null|exact=JSString|powerset=1], powerset: 0)*/
constIntStringMap() => const {1: 'a', 2: 'b', 3: 'c'};
