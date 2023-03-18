// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null]*/
main() {
  useRecord1();
  useRecord2();
  useRecord3();
}

/*member: getRecord1:[Record(RecordShape(2), [[exact=JSUInt31], [exact=JSUInt31]])]*/
(num, num) getRecord1() => (1, 1);
/*member: getRecord2:[Record(RecordShape(2), [Value([exact=JSBool], value: true), Value([exact=JSBool], value: false)])]*/
(bool, bool) getRecord2() => (true, false);
/*member: getRecord3:[Record(RecordShape(2), [Value([exact=JSString], value: "a"), Value([exact=JSString], value: "b")])]*/
dynamic getRecord3() => ('a', 'b');

/*member: useRecord1:[exact=JSUInt31]*/
useRecord1() {
  final r = getRecord1();
  return r
      . /*[Record(RecordShape(2), [[exact=JSUInt31], [exact=JSUInt31]])]*/ $1;
}

/*member: useRecord2:Value([exact=JSBool], value: false)*/
useRecord2() {
  final r = getRecord2();
  return r
      . /*[Record(RecordShape(2), [Value([exact=JSBool], value: true), Value([exact=JSBool], value: false)])]*/ $2;
}

/*member: useRecord3:Value([exact=JSString], value: "b")*/
useRecord3() {
  final r = getRecord3();
  return r
      . /*[Record(RecordShape(2), [Value([exact=JSString], value: "a"), Value([exact=JSString], value: "b")])]*/ $2;
}
