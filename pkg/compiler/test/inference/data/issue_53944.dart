// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make sure first and last selectors properly update types.

/*member: testUnchangedFirst:[null]*/
void testUnchangedFirst(/*Value([exact=JSBool], value: true)*/ x) {}

/*member: testFirst1:[null]*/
void testFirst1(/*[exact=JSBool]*/ x) {}

/*member: testFirst2:[null]*/
void testFirst2(/*[exact=JSBool]*/ x) {}

/*member: testUnchangedLast:[null]*/
void testUnchangedLast(/*Value([exact=JSBool], value: true)*/ x) {}

/*member: testLast1:[null]*/
void testLast1(/*[exact=JSBool]*/ x) {}

/*member: testLast2:[null]*/
void testLast2(/*[exact=JSBool]*/ x) {}

/*member: main:[null]*/
main() {
  final List<Object> x = [true, true];
  testFirst1(x
      . /*Container([exact=JSExtendableArray], element: [exact=JSBool], length: 2)*/ first);
  x. /*update: Container([exact=JSExtendableArray], element: [exact=JSBool], length: 2)*/ first =
      false;
  testFirst2(x
      . /*Container([exact=JSExtendableArray], element: [exact=JSBool], length: 2)*/ first);

  final List<Object> y = [true, true];
  testLast1(y
      . /*Container([exact=JSExtendableArray], element: [exact=JSBool], length: 2)*/ first);
  y. /*update: Container([exact=JSExtendableArray], element: [exact=JSBool], length: 2)*/ last =
      false;
  testLast2(y
      . /*Container([exact=JSExtendableArray], element: [exact=JSBool], length: 2)*/ first);

  final List<Object> z = [true, true];
  testUnchangedFirst(z
      . /*Container([exact=JSExtendableArray], element: Value([exact=JSBool], value: true), length: 2)*/ first);
  testUnchangedLast(z
      . /*Container([exact=JSExtendableArray], element: Value([exact=JSBool], value: true), length: 2)*/ last);
}
