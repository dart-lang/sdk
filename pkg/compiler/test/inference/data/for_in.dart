// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  forInDirect();
  forInReturn();
  forInReturnMulti();
  forInReturnNonNull();
}

////////////////////////////////////////////////////////////////////////////////
// For-in loop directly on a list literal.
////////////////////////////////////////////////////////////////////////////////

/*member: forInDirect:[null|powerset={null}]*/
forInDirect() {
  /*iterator: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 3, powerset: {I}{G}{M})*/
  /*current: [exact=ArrayIterator|powerset={N}{O}{N}]*/
  /*moveNext: [exact=ArrayIterator|powerset={N}{O}{N}]*/
  for (var a in [1, 2, 3]) {
    print(a);
  }
}

////////////////////////////////////////////////////////////////////////////////
// Return element from a for-in loop on a list literal.
////////////////////////////////////////////////////////////////////////////////

/*member: forInReturn:[null|subclass=JSInt|powerset={null}{I}{O}{N}]*/
forInReturn() {
  /*iterator: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 3, powerset: {I}{G}{M})*/
  /*current: [exact=ArrayIterator|powerset={N}{O}{N}]*/
  /*moveNext: [exact=ArrayIterator|powerset={N}{O}{N}]*/
  for (var a in [1, 2, 3]) {
    // TODO(johnniwinther): We should know the type of [a] here.
    return a;
  }
}

////////////////////////////////////////////////////////////////////////////////
// Return element from a for-in loop on known list type.
////////////////////////////////////////////////////////////////////////////////

/*member: _forInReturn:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
_forInReturn(
  /*Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: null, powerset: {I}{G}{M})*/ list,
) {
  /*iterator: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: null, powerset: {I}{G}{M})*/
  /*current: [exact=ArrayIterator|powerset={N}{O}{N}]*/
  /*moveNext: [exact=ArrayIterator|powerset={N}{O}{N}]*/
  for (var a in list) {
    // TODO(johnniwinther): We should know the type of [a] here.
    return a;
  }
}

/*member: forInReturnMulti:[null|powerset={null}]*/
forInReturnMulti() {
  _forInReturn([1, 2]);
  _forInReturn([1, 2, 3]);
}

////////////////////////////////////////////////////////////////////////////////
// Sequentially refine that an element is not null and return it from a for-in
// loop on known list type.
////////////////////////////////////////////////////////////////////////////////

/*member: forInReturnNonNull:[subclass=JSInt|powerset={I}{O}{N}]*/
forInReturnNonNull() {
  /*iterator: Container([exact=JSExtendableArray|powerset={I}{G}{M}], element: [exact=JSUInt31|powerset={I}{O}{N}], length: 3, powerset: {I}{G}{M})*/
  /*current: [exact=ArrayIterator|powerset={N}{O}{N}]*/
  /*moveNext: [exact=ArrayIterator|powerset={N}{O}{N}]*/
  for (var a in [1, 2, 3]) {
    // TODO(johnniwinther): We should know the type of [a] here. Even if [a] has
    // type `dynamic`.
    a. /*[subclass=JSInt|powerset={I}{O}{N}]*/ isEven;
    a. /*[subclass=JSInt|powerset={I}{O}{N}]*/ isEven;
    return a;
  }
  return 0;
}
