// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make sure first and last selectors properly update types.

/*member: testUnchangedFirst:[null|powerset=1]*/
void testUnchangedFirst(
  /*Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/ x,
) {}

/*member: testFirst1:[null|powerset=1]*/
void testFirst1(/*[exact=JSBool|powerset=0]*/ x) {}

/*member: testFirst2:[null|powerset=1]*/
void testFirst2(/*[exact=JSBool|powerset=0]*/ x) {}

/*member: testUnchangedLast:[null|powerset=1]*/
void testUnchangedLast(
  /*Value([exact=JSBool|powerset=0], value: true, powerset: 0)*/ x,
) {}

/*member: testLast1:[null|powerset=1]*/
void testLast1(/*[exact=JSBool|powerset=0]*/ x) {}

/*member: testLast2:[null|powerset=1]*/
void testLast2(/*[exact=JSBool|powerset=0]*/ x) {}

/*member: main:[null|powerset=1]*/
main() {
  final List<Object> x = [true, true];
  testFirst1(
    x. /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSBool|powerset=0], length: 2, powerset: 0)*/ first,
  );
  x. /*update: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSBool|powerset=0], length: 2, powerset: 0)*/ first =
      false;
  testFirst2(
    x. /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSBool|powerset=0], length: 2, powerset: 0)*/ first,
  );

  final List<Object> y = [true, true];
  testLast1(
    y. /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSBool|powerset=0], length: 2, powerset: 0)*/ first,
  );
  y. /*update: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSBool|powerset=0], length: 2, powerset: 0)*/ last =
      false;
  testLast2(
    y. /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSBool|powerset=0], length: 2, powerset: 0)*/ first,
  );

  final List<Object> z = [true, true];
  testUnchangedFirst(
    z. /*Container([exact=JSExtendableArray|powerset=0], element: Value([exact=JSBool|powerset=0], value: true, powerset: 0), length: 2, powerset: 0)*/ first,
  );
  testUnchangedLast(
    z. /*Container([exact=JSExtendableArray|powerset=0], element: Value([exact=JSBool|powerset=0], value: true, powerset: 0), length: 2, powerset: 0)*/ last,
  );
}
