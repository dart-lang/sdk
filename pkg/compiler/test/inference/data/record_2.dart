// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  useRecord1(true);
  useRecord1(false);
  useRecord2(true);
  useRecord2(false);
  useRecord3(true);
  useRecord3(false);
  useRecord4(true);
  useRecord4(false);
  useRecord5(true);
  useRecord5(false);
}

/*member: getRecord1:[Record(RecordShape(2), [[exact=JSUInt31|powerset=0], [exact=JSUInt31|powerset=0]], powerset: 0)]*/
(num, num) getRecord1() => (1, 1);
/*member: getRecord2:[Record(RecordShape(2), [Value([exact=JSBool|powerset=0], value: true, powerset: 0), Value([exact=JSBool|powerset=0], value: false, powerset: 0)], powerset: 0)]*/
(bool, bool) getRecord2() => (true, false);
/*member: getRecord3:[Record(RecordShape(2), [Value([exact=JSString|powerset=0], value: "a", powerset: 0), Container([exact=JSUnmodifiableArray|powerset=0], element: [empty|powerset=0], length: 0, powerset: 0)], powerset: 0)]*/
dynamic getRecord3() => ('a', const []);
/*member: getRecord4:[Record(RecordShape(2), [Union([exact=JSBool|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), Union([exact=JSBool|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)], powerset: 0)]*/
dynamic getRecord4(bool /*[exact=JSBool|powerset=0]*/ b) =>
    b ? getRecord1() : getRecord2();

/*member: useRecord1:Union([exact=JSBool|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
useRecord1(bool /*[exact=JSBool|powerset=0]*/ b) {
  final r = getRecord4(b);
  return r
      . /*[Record(RecordShape(2), [Union([exact=JSBool|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), Union([exact=JSBool|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)], powerset: 0)]*/ $2;
}

/*member: useRecord2:Value([exact=JSBool|powerset=0], value: false, powerset: 0)*/
useRecord2(bool /*[exact=JSBool|powerset=0]*/ b) {
  final r = b ? getRecord2() : getRecord2();
  return r
      . /*[Record(RecordShape(2), [Value([exact=JSBool|powerset=0], value: true, powerset: 0), Value([exact=JSBool|powerset=0], value: false, powerset: 0)], powerset: 0)]*/ $2;
}

/*member: useRecord3:Union([exact=JSBool|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
useRecord3(bool /*[exact=JSBool|powerset=0]*/ b) {
  final r = b ? getRecord2() : getRecord1();
  return r
      . /*[Record(RecordShape(2), [Union([exact=JSBool|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), Union([exact=JSBool|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)], powerset: 0)]*/ $2;
}

/*member: useRecord4:Union([exact=JSBool|powerset=0], [exact=JSUnmodifiableArray|powerset=0], powerset: 0)*/
useRecord4(bool /*[exact=JSBool|powerset=0]*/ b) {
  final r = b ? getRecord2() : getRecord3();
  return r
      . /*[Record(RecordShape(2), [Union([exact=JSBool|powerset=0], [exact=JSString|powerset=0], powerset: 0), Union([exact=JSBool|powerset=0], [exact=JSUnmodifiableArray|powerset=0], powerset: 0)], powerset: 0)]*/ $2;
}

/*member: useRecord5:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
useRecord5(bool /*[exact=JSBool|powerset=0]*/ b) {
  final c = /*[Record(RecordShape(2), [Value([exact=JSString|powerset=0], value: "a", powerset: 0), Value([exact=JSString|powerset=0], value: "b", powerset: 0)], powerset: 0)]*/
      () => ('a', 'b');
  return (b ? c() : (3, 4))
      . /*[Record(RecordShape(2), [Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0), Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)], powerset: 0)]*/ $1;
}
