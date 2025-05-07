// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  useRecord1();
  useRecord2();
  useRecord3();
}

/*member: getRecord1:[Record(RecordShape(2), [[exact=JSUInt31|powerset={I}], [exact=JSUInt31|powerset={I}]], powerset: {N})]*/
(num, num) getRecord1() => (1, 1);
/*member: getRecord2:[Record(RecordShape(2), [Value([exact=JSBool|powerset={I}], value: true, powerset: {I}), Value([exact=JSBool|powerset={I}], value: false, powerset: {I})], powerset: {N})]*/
(bool, bool) getRecord2() => (true, false);
/*member: getRecord3:[Record(RecordShape(2), [Value([exact=JSString|powerset={I}], value: "a", powerset: {I}), Value([exact=JSString|powerset={I}], value: "b", powerset: {I})], powerset: {N})]*/
dynamic getRecord3() => ('a', 'b');

/*member: useRecord1:[exact=JSUInt31|powerset={I}]*/
useRecord1() {
  final r = getRecord1();
  return r
      . /*[Record(RecordShape(2), [[exact=JSUInt31|powerset={I}], [exact=JSUInt31|powerset={I}]], powerset: {N})]*/ $1;
}

/*member: useRecord2:Value([exact=JSBool|powerset={I}], value: false, powerset: {I})*/
useRecord2() {
  final r = getRecord2();
  return r
      . /*[Record(RecordShape(2), [Value([exact=JSBool|powerset={I}], value: true, powerset: {I}), Value([exact=JSBool|powerset={I}], value: false, powerset: {I})], powerset: {N})]*/ $2;
}

/*member: useRecord3:Value([exact=JSString|powerset={I}], value: "b", powerset: {I})*/
useRecord3() {
  final r = getRecord3();
  return r
      . /*[Record(RecordShape(2), [Value([exact=JSString|powerset={I}], value: "a", powerset: {I}), Value([exact=JSString|powerset={I}], value: "b", powerset: {I})], powerset: {N})]*/ $2;
}
