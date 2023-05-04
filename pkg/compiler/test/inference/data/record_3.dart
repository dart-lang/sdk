// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null]*/
void main() {
  useRecords1(true);
  useRecords1(false);
  useRecords2(true);
  useRecords2(false);
  useRecords3(true);
  useRecords3(false);
  useRecords4(true);
  useRecords4(false);
  useRecords5(true, false);
  useRecords5(false, true);
  useRecords6(true);
  useRecords6(false);
  useRecords7(true);
  useRecords7(false);
}

/*member: getRecord1:[Record(RecordShape(3), [[exact=JSUInt31], [exact=JSUInt31], [exact=JSUInt31]])]*/
getRecord1() => (1, 2, 3);
/*member: getRecord2:[Record(RecordShape(1), [Value([exact=JSString], value: "a")])]*/
getRecord2() => ('a',);
/*member: getRecord3:[Record(RecordShape(0, {age, name}), [[exact=JSUInt31], Value([exact=JSString], value: "Alice")])]*/
getRecord3() => (name: 'Alice', age: 28);
/*member: getRecord4:[Record(RecordShape(0, {height, name}), [[exact=JSUInt31], Value([exact=JSString], value: "Bob")])]*/
getRecord4() => (name: 'Bob', height: 28);
/*member: getUnion:Union([exact=JSString], [exact=JSUInt31])*/
getUnion(bool /*[exact=JSBool]*/ b) => b ? 3 : 'a';

/*member: useRecords1:Union([exact=JSString], [exact=JSUInt31])*/
useRecords1(bool /*[exact=JSBool]*/ b) {
  return (b ? getRecord1() : getRecord2())
      . /*Union([exact=_Record_1], [exact=_Record_3])*/ $1;
}

/*member: useRecords2:Union([exact=_Record_1], [exact=_Record_3])*/
useRecords2(bool /*[exact=JSBool]*/ b) {
  return b ? getRecord1() : getRecord2();
}

/*member: useRecords3:Union([exact=_Record_1], [exact=_Record_2_age_name])*/
useRecords3(bool /*[exact=JSBool]*/ b) {
  return b ? getRecord2() : getRecord3();
}

/*member: useRecords4:Union([exact=_Record_2_age_name], [exact=_Record_3])*/
useRecords4(bool /*[exact=JSBool]*/ b) {
  return b ? getRecord1() : getRecord3();
}

/*member: useRecords5:Union([exact=_Record_1], [exact=_Record_2_age_name], [exact=_Record_3])*/
useRecords5(bool /*[exact=JSBool]*/ b1, bool /*[exact=JSBool]*/ b2) {
  return b1
      ? getRecord2()
      : b2
          ? getRecord3()
          : getRecord1();
}

/*member: useRecords6:Union([exact=_Record_2_age_name], [exact=_Record_2_height_name])*/
useRecords6(bool /*[exact=JSBool]*/ b) {
  return b ? getRecord3() : getRecord4();
}

/*member: useRecords7:Union([exact=JSString], [exact=JSUInt31], [exact=_Record_1])*/
useRecords7(bool /*[exact=JSBool]*/ b) {
  return b ? getUnion(b) : getRecord2();
}
