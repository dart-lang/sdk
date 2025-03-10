// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  forInDirect();
  forInReturn();
  forInReturnMulti();
  forInReturnNonNull();
}

////////////////////////////////////////////////////////////////////////////////
// For-in loop directly on a list literal.
////////////////////////////////////////////////////////////////////////////////

/*member: forInDirect:[null|powerset=1]*/
forInDirect() {
  /*iterator: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 3, powerset: 0)*/
  /*current: [exact=ArrayIterator|powerset=0]*/
  /*moveNext: [exact=ArrayIterator|powerset=0]*/
  for (var a in [1, 2, 3]) {
    print(a);
  }
}

////////////////////////////////////////////////////////////////////////////////
// Return element from a for-in loop on a list literal.
////////////////////////////////////////////////////////////////////////////////

/*member: forInReturn:[null|subclass=JSInt|powerset=1]*/
forInReturn() {
  /*iterator: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 3, powerset: 0)*/
  /*current: [exact=ArrayIterator|powerset=0]*/
  /*moveNext: [exact=ArrayIterator|powerset=0]*/
  for (var a in [1, 2, 3]) {
    // TODO(johnniwinther): We should know the type of [a] here.
    return a;
  }
}

////////////////////////////////////////////////////////////////////////////////
// Return element from a for-in loop on known list type.
////////////////////////////////////////////////////////////////////////////////

/*member: _forInReturn:[null|subclass=Object|powerset=1]*/
_forInReturn(
  /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: null, powerset: 0)*/ list,
) {
  /*iterator: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: null, powerset: 0)*/
  /*current: [exact=ArrayIterator|powerset=0]*/
  /*moveNext: [exact=ArrayIterator|powerset=0]*/
  for (var a in list) {
    // TODO(johnniwinther): We should know the type of [a] here.
    return a;
  }
}

/*member: forInReturnMulti:[null|powerset=1]*/
forInReturnMulti() {
  _forInReturn([1, 2]);
  _forInReturn([1, 2, 3]);
}

////////////////////////////////////////////////////////////////////////////////
// Sequentially refine that an element is not null and return it from a for-in
// loop on known list type.
////////////////////////////////////////////////////////////////////////////////

/*member: forInReturnNonNull:[subclass=JSInt|powerset=0]*/
forInReturnNonNull() {
  /*iterator: Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 3, powerset: 0)*/
  /*current: [exact=ArrayIterator|powerset=0]*/
  /*moveNext: [exact=ArrayIterator|powerset=0]*/
  for (var a in [1, 2, 3]) {
    // TODO(johnniwinther): We should know the type of [a] here. Even if [a] has
    // type `dynamic`.
    a. /*[subclass=JSInt|powerset=0]*/ isEven;
    a. /*[subclass=JSInt|powerset=0]*/ isEven;
    return a;
  }
  return 0;
}
