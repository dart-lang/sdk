// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
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

/*member: getRecord1:[Record(RecordShape(3), [[exact=JSUInt31|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}]], powerset: {N}{O}{N})]*/
getRecord1() => (1, 2, 3);
/*member: getRecord2:[Record(RecordShape(1), [Value([exact=JSString|powerset={I}{O}{I}], value: "a", powerset: {I}{O}{I})], powerset: {N}{O}{N})]*/
getRecord2() => ('a',);
/*member: getRecord3:[Record(RecordShape(0, {age, name}), [[exact=JSUInt31|powerset={I}{O}{N}], Value([exact=JSString|powerset={I}{O}{I}], value: "Alice", powerset: {I}{O}{I})], powerset: {N}{O}{N})]*/
getRecord3() => (name: 'Alice', age: 28);
/*member: getRecord4:[Record(RecordShape(0, {height, name}), [[exact=JSUInt31|powerset={I}{O}{N}], Value([exact=JSString|powerset={I}{O}{I}], value: "Bob", powerset: {I}{O}{I})], powerset: {N}{O}{N})]*/
getRecord4() => (name: 'Bob', height: 28);
/*member: getUnion:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
getUnion(bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b) => b ? 3 : 'a';

/*member: useRecords1:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{IN})*/
useRecords1(bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  return (b ? getRecord1() : getRecord2())
      . /*Union([exact=_Record_1|powerset={N}{O}{N}], [exact=_Record_3|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ $1;
}

/*member: useRecords2:Union([exact=_Record_1|powerset={N}{O}{N}], [exact=_Record_3|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
useRecords2(bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  return b ? getRecord1() : getRecord2();
}

/*member: useRecords3:Union([exact=_Record_1|powerset={N}{O}{N}], [exact=_Record_2_age_name|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
useRecords3(bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  return b ? getRecord2() : getRecord3();
}

/*member: useRecords4:Union([exact=_Record_2_age_name|powerset={N}{O}{N}], [exact=_Record_3|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
useRecords4(bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  return b ? getRecord1() : getRecord3();
}

/*member: useRecords5:Union([exact=_Record_1|powerset={N}{O}{N}], [exact=_Record_2_age_name|powerset={N}{O}{N}], [exact=_Record_3|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
useRecords5(
  bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b1,
  bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b2,
) {
  return b1
      ? getRecord2()
      : b2
      ? getRecord3()
      : getRecord1();
}

/*member: useRecords6:Union([exact=_Record_2_age_name|powerset={N}{O}{N}], [exact=_Record_2_height_name|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
useRecords6(bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  return b ? getRecord3() : getRecord4();
}

/*member: useRecords7:Union([exact=JSString|powerset={I}{O}{I}], [exact=JSUInt31|powerset={I}{O}{N}], [exact=_Record_1|powerset={N}{O}{N}], powerset: {IN}{O}{IN})*/
useRecords7(bool /*[exact=JSBool|powerset={I}{O}{N}]*/ b) {
  return b ? getUnion(b) : getRecord2();
}
