// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: getRecord1:[Record(RecordShape(2), [[exact=JSUInt31|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}]], powerset: {N}{O})]*/
(num, num) getRecord1() => (1, 1);
/*member: getRecord2:[Record(RecordShape(2), [Value([exact=JSBool|powerset={I}{O}], value: true, powerset: {I}{O}), Value([exact=JSBool|powerset={I}{O}], value: false, powerset: {I}{O})], powerset: {N}{O})]*/
(bool, bool) getRecord2() => (true, false);
/*member: getRecord3:[Record(RecordShape(2), [Value([exact=JSString|powerset={I}{O}], value: "a", powerset: {I}{O}), Container([exact=JSUnmodifiableArray|powerset={I}{U}], element: [empty|powerset=empty], length: 0, powerset: {I}{U})], powerset: {N}{O})]*/
dynamic getRecord3() => ('a', const []);
/*member: getRecord4:[Record(RecordShape(2), [Union([exact=JSBool|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O}), Union([exact=JSBool|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})], powerset: {N}{O})]*/
dynamic getRecord4(bool /*[exact=JSBool|powerset={I}{O}]*/ b) =>
    b ? getRecord1() : getRecord2();

/*member: useRecord1:Union([exact=JSBool|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
useRecord1(bool /*[exact=JSBool|powerset={I}{O}]*/ b) {
  final r = getRecord4(b);
  return r
      . /*[Record(RecordShape(2), [Union([exact=JSBool|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O}), Union([exact=JSBool|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})], powerset: {N}{O})]*/ $2;
}

/*member: useRecord2:Value([exact=JSBool|powerset={I}{O}], value: false, powerset: {I}{O})*/
useRecord2(bool /*[exact=JSBool|powerset={I}{O}]*/ b) {
  final r = b ? getRecord2() : getRecord2();
  return r
      . /*[Record(RecordShape(2), [Value([exact=JSBool|powerset={I}{O}], value: true, powerset: {I}{O}), Value([exact=JSBool|powerset={I}{O}], value: false, powerset: {I}{O})], powerset: {N}{O})]*/ $2;
}

/*member: useRecord3:Union([exact=JSBool|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
useRecord3(bool /*[exact=JSBool|powerset={I}{O}]*/ b) {
  final r = b ? getRecord2() : getRecord1();
  return r
      . /*[Record(RecordShape(2), [Union([exact=JSBool|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O}), Union([exact=JSBool|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})], powerset: {N}{O})]*/ $2;
}

/*member: useRecord4:Union([exact=JSBool|powerset={I}{O}], [exact=JSUnmodifiableArray|powerset={I}{U}], powerset: {I}{UO})*/
useRecord4(bool /*[exact=JSBool|powerset={I}{O}]*/ b) {
  final r = b ? getRecord2() : getRecord3();
  return r
      . /*[Record(RecordShape(2), [Union([exact=JSBool|powerset={I}{O}], [exact=JSString|powerset={I}{O}], powerset: {I}{O}), Union([exact=JSBool|powerset={I}{O}], [exact=JSUnmodifiableArray|powerset={I}{U}], powerset: {I}{UO})], powerset: {N}{O})]*/ $2;
}

/*member: useRecord5:Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})*/
useRecord5(bool /*[exact=JSBool|powerset={I}{O}]*/ b) {
  final c = /*[Record(RecordShape(2), [Value([exact=JSString|powerset={I}{O}], value: "a", powerset: {I}{O}), Value([exact=JSString|powerset={I}{O}], value: "b", powerset: {I}{O})], powerset: {N}{O})]*/
      () => ('a', 'b');
  return (b ? c() : (3, 4))
      . /*[Record(RecordShape(2), [Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O}), Union([exact=JSString|powerset={I}{O}], [exact=JSUInt31|powerset={I}{O}], powerset: {I}{O})], powerset: {N}{O})]*/ $1;
}
