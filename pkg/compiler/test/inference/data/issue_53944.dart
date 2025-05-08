// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make sure first and last selectors properly update types.

/*member: testUnchangedFirst:[null|powerset={null}]*/
void testUnchangedFirst(
  /*Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/ x,
) {}

/*member: testFirst1:[null|powerset={null}]*/
void testFirst1(/*[exact=JSBool|powerset={I}{O}{N}]*/ x) {}

/*member: testFirst2:[null|powerset={null}]*/
void testFirst2(/*[exact=JSBool|powerset={I}{O}{N}]*/ x) {}

/*member: testUnchangedLast:[null|powerset={null}]*/
void testUnchangedLast(
  /*Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N})*/ x,
) {}

/*member: testLast1:[null|powerset={null}]*/
void testLast1(/*[exact=JSBool|powerset={I}{O}{N}]*/ x) {}

/*member: testLast2:[null|powerset={null}]*/
void testLast2(/*[exact=JSBool|powerset={I}{O}{N}]*/ x) {}

/*member: main:[null|powerset={null}]*/
main() {
  final List<Object> x = [true, true];
  testFirst1(
    x. /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSBool|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M})*/ first,
  );
  x. /*update: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSBool|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M})*/ first =
      false;
  testFirst2(
    x. /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSBool|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M})*/ first,
  );

  final List<Object> y = [true, true];
  testLast1(
    y. /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSBool|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M})*/ first,
  );
  y. /*update: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSBool|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M})*/ last =
      false;
  testLast2(
    y. /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSBool|powerset={I}{O}{N}], length: 2, powerset: {I}{G}{M})*/ first,
  );

  final List<Object> z = [true, true];
  testUnchangedFirst(
    z. /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N}), length: 2, powerset: {I}{G}{M})*/ first,
  );
  testUnchangedLast(
    z. /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: Value([exact=JSBool|powerset={I}{O}{N}], value: true, powerset: {I}{O}{N}), length: 2, powerset: {I}{G}{M})*/ last,
  );
}
