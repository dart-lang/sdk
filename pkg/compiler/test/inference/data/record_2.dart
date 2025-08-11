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

/*member: getRecord1:[Record(RecordShape(2), [[exact=JSUInt31|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}]], powerset: {N}{O}{N})]*/
(num, num) getRecord1() => (1, 1);
/*member: getRecord2:[Record(RecordShape(2), [Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N}), Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})], powerset: {N}{O}{N})]*/
(bool, bool) getRecord2() => (true, false);
/*member: getRecord3:[Record(RecordShape(2), [Value([exact=JSString|powerset={I}{O}{I}], value: "a", powerset: {I}{O}{I}), Container([exact=JSUnmodifiableArray|powerset={I}{U}{I}], element: [empty|powerset=empty], length: 0, powerset: {I}{U}{I})], powerset: {N}{O}{N})]*/
dynamic getRecord3() => ('a', const []);
/*member: getRecord4:[Record(RecordShape(2), [Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N}), Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})], powerset: {N}{O}{N})]*/
dynamic getRecord4(bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b) =>
    b ? getRecord1() : getRecord2();

/*member: useRecord1:Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/
useRecord1(bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  final r = getRecord4(b);
  return r
      . /*[Record(RecordShape(2), [Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N}), Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})], powerset: {N}{O}{N})]*/ $2;
}

/*member: useRecord2:Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})*/
useRecord2(bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  final r = b ? getRecord2() : getRecord2();
  return r
      . /*[Record(RecordShape(2), [Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N}), Value([exact=JSBool|powerset={I}{O}{N}], value: false, powerset: {I}{O}{N})], powerset: {N}{O}{N})]*/ $2;
}

/*member: useRecord3:Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/
useRecord3(bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  final r = b ? getRecord2() : getRecord1();
  return r
      . /*[Record(RecordShape(2), [Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N}), Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})], powerset: {N}{O}{N})]*/ $2;
}

/*member: useRecord4:Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSUnmodifiableArray|powerset={I}{U}{I}], powerset: {I}{UO}{IN})*/
useRecord4(bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  final r = b ? getRecord2() : getRecord3();
  return r
      . /*[Record(RecordShape(2), [Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSString|powerset={I}{O}{I}], powerset: {I}{O}{IN}), Union([exact=JSBool|powerset={I}{O}{N}], [exact=JSUnmodifiableArray|powerset={I}{U}{I}], powerset: {I}{UO}{IN})], powerset: {N}{O}{N})]*/ $2;
}

/*member: useRecord5:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
useRecord5(bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  final c = /*[Record(RecordShape(2), [Value([exact=JSString|powerset={I}{O}{I}], value: "a", powerset: {I}{O}{I}), Value([exact=JSString|powerset={I}{O}{I}], value: "b", powerset: {I}{O}{I})], powerset: {N}{O}{N})]*/
      () => ('a', 'b');
  return (b ? c() : (3, 4))
      . /*[Record(RecordShape(2), [Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN}), Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})], powerset: {N}{O}{N})]*/ $1;
}
