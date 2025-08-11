// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  useRecord1();
  useRecord2();
  useRecord3();
}

/*member: getRecord1:[Record(RecordShape(2), [[exact=JSUInt31|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}]], powerset: {N}{O}{N})]*/
(num, num) getRecord1() => (1, 1);
/*member: getRecord2:[Record(RecordShape(2), [Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N}), Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})], powerset: {N}{O}{N})]*/
(bool, bool) getRecord2() => (true, false);
/*member: getRecord3:[Record(RecordShape(2), [Value([exact=JSString|powerset={I}{O}{I}], value: "a", powerset: {I}{O}{I}), Value([exact=JSString|powerset={I}{O}{I}], value: "b", powerset: {I}{O}{I})], powerset: {N}{O}{N})]*/
dynamic getRecord3() => ('a', 'b');

/*member: useRecord1:[exact=JSUInt31|powerset={I}{O}{N}]*/
useRecord1() {
  final r = getRecord1();
  return r
      . /*[Record(RecordShape(2), [[exact=JSUInt31|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}]], powerset: {N}{O}{N})]*/ $1;
}

/*member: useRecord2:Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})*/
useRecord2() {
  final r = getRecord2();
  return r
      . /*[Record(RecordShape(2), [Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N}), Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})], powerset: {N}{O}{N})]*/ $2;
}

/*member: useRecord3:Value([exact=JSString|powerset={I}{O}{I}], value: "b", powerset: {I}{O}{I})*/
useRecord3() {
  final r = getRecord3();
  return r
      . /*[Record(RecordShape(2), [Value([exact=JSString|powerset={I}{O}{I}], value: "a", powerset: {I}{O}{I}), Value([exact=JSString|powerset={I}{O}{I}], value: "b", powerset: {I}{O}{I})], powerset: {N}{O}{N})]*/ $2;
}
