// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  useRecord1();
  useRecord2();
  useRecord3();
}

/*member: getRecord1:[Record(RecordShape(2), [[exact=JSUInt31|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}]], powerset: {N}{O})]*/
(num, num) getRecord1() => (1, 1);
/*member: getRecord2:[Record(RecordShape(2), [Value([exact=JSBool|powerset={I}{O}], value: true, powerset: {I}{O}), Value([exact=JSBool|powerset={I}{O}], value: false, powerset: {I}{O})], powerset: {N}{O})]*/
(bool, bool) getRecord2() => (true, false);
/*member: getRecord3:[Record(RecordShape(2), [Value([exact=JSString|powerset={I}{O}], value: "a", powerset: {I}{O}), Value([exact=JSString|powerset={I}{O}], value: "b", powerset: {I}{O})], powerset: {N}{O})]*/
dynamic getRecord3() => ('a', 'b');

/*member: useRecord1:[exact=JSUInt31|powerset={I}{O}]*/
useRecord1() {
  final r = getRecord1();
  return r
      . /*[Record(RecordShape(2), [[exact=JSUInt31|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}]], powerset: {N}{O})]*/ $1;
}

/*member: useRecord2:Value([exact=JSBool|powerset={I}{O}], value: false, powerset: {I}{O})*/
useRecord2() {
  final r = getRecord2();
  return r
      . /*[Record(RecordShape(2), [Value([exact=JSBool|powerset={I}{O}], value: true, powerset: {I}{O}), Value([exact=JSBool|powerset={I}{O}], value: false, powerset: {I}{O})], powerset: {N}{O})]*/ $2;
}

/*member: useRecord3:Value([exact=JSString|powerset={I}{O}], value: "b", powerset: {I}{O})*/
useRecord3() {
  final r = getRecord3();
  return r
      . /*[Record(RecordShape(2), [Value([exact=JSString|powerset={I}{O}], value: "a", powerset: {I}{O}), Value([exact=JSString|powerset={I}{O}], value: "b", powerset: {I}{O})], powerset: {N}{O})]*/ $2;
}
