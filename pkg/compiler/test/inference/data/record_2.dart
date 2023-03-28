// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null]*/
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

/*member: getRecord1:[Record(RecordShape(2), [[exact=JSUInt31], [exact=JSUInt31]])]*/
(num, num) getRecord1() => (1, 1);
/*member: getRecord2:[Record(RecordShape(2), [Value([exact=JSBool], value: true), Value([exact=JSBool], value: false)])]*/
(bool, bool) getRecord2() => (true, false);
/*member: getRecord3:[Record(RecordShape(2), [Value([exact=JSString], value: "a"), Container([exact=JSUnmodifiableArray], element: [empty], length: 0)])]*/
dynamic getRecord3() => ('a', const []);
/*member: getRecord4:[Record(RecordShape(2), [Union([exact=JSBool], [exact=JSUInt31]), Union([exact=JSBool], [exact=JSUInt31])])]*/
dynamic getRecord4(bool /*[exact=JSBool]*/ b) =>
    b ? getRecord1() : getRecord2();

/*member: useRecord1:Union([exact=JSBool], [exact=JSUInt31])*/
useRecord1(bool /*[exact=JSBool]*/ b) {
  final r = getRecord4(b);
  return r
      . /*[Record(RecordShape(2), [Union([exact=JSBool], [exact=JSUInt31]), Union([exact=JSBool], [exact=JSUInt31])])]*/ $2;
}

/*member: useRecord2:Value([exact=JSBool], value: false)*/
useRecord2(bool /*[exact=JSBool]*/ b) {
  final r = b ? getRecord2() : getRecord2();
  return r
      . /*[Record(RecordShape(2), [Value([exact=JSBool], value: true), Value([exact=JSBool], value: false)])]*/ $2;
}

/*member: useRecord3:Union([exact=JSBool], [exact=JSUInt31])*/
useRecord3(bool /*[exact=JSBool]*/ b) {
  final r = b ? getRecord2() : getRecord1();
  return r
      . /*[Record(RecordShape(2), [Union([exact=JSBool], [exact=JSUInt31]), Union([exact=JSBool], [exact=JSUInt31])])]*/ $2;
}

/*member: useRecord4:Union([exact=JSBool], [exact=JSUnmodifiableArray])*/
useRecord4(bool /*[exact=JSBool]*/ b) {
  final r = b ? getRecord2() : getRecord3();
  return r
      . /*[Record(RecordShape(2), [Union([exact=JSBool], [exact=JSString]), Union([exact=JSBool], [exact=JSUnmodifiableArray])])]*/ $2;
}

/*member: useRecord5:Union([exact=JSString], [exact=JSUInt31])*/
useRecord5(bool /*[exact=JSBool]*/ b) {
  final c = /*[Record(RecordShape(2), [Value([exact=JSString], value: "a"), Value([exact=JSString], value: "b")])]*/
      () => ('a', 'b');
  return (b ? c() : (3, 4))
      . /*[Record(RecordShape(2), [Union([exact=JSString], [exact=JSUInt31]), Union([exact=JSString], [exact=JSUInt31])])]*/ $1;
}
