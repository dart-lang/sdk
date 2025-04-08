// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  useRecord1();
  useRecord2();
  useRecord3();
}

/*member: getRecord1:[Record(RecordShape(2), [[exact=JSUInt31|powerset=0], [exact=JSUInt31|powerset=0]], powerset: 0)]*/
(num, num) getRecord1() => (1, 1);
/*member: getRecord2:[Record(RecordShape(2), [Value([exact=JSBool|powerset=0], value: true, powerset: 0), Value([exact=JSBool|powerset=0], value: false, powerset: 0)], powerset: 0)]*/
(bool, bool) getRecord2() => (true, false);
/*member: getRecord3:[Record(RecordShape(2), [Value([exact=JSString|powerset=0], value: "a", powerset: 0), Value([exact=JSString|powerset=0], value: "b", powerset: 0)], powerset: 0)]*/
dynamic getRecord3() => ('a', 'b');

/*member: useRecord1:[exact=JSUInt31|powerset=0]*/
useRecord1() {
  final r = getRecord1();
  return r
      . /*[Record(RecordShape(2), [[exact=JSUInt31|powerset=0], [exact=JSUInt31|powerset=0]], powerset: 0)]*/ $1;
}

/*member: useRecord2:Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/
useRecord2() {
  final r = getRecord2();
  return r
      . /*[Record(RecordShape(2), [Value([exact=JSBool|powerset=0], value: true, powerset: 0), Value([exact=JSBool|powerset=0], value: false, powerset: 0)], powerset: 0)]*/ $2;
}

/*member: useRecord3:Value([exact=JSString|powerset=0], value: "b", powerset: 0)*/
useRecord3() {
  final r = getRecord3();
  return r
      . /*[Record(RecordShape(2), [Value([exact=JSString|powerset=0], value: "a", powerset: 0), Value([exact=JSString|powerset=0], value: "b", powerset: 0)], powerset: 0)]*/ $2;
}
