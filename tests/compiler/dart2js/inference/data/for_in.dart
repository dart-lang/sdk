// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  forInDirect();
  forInReturn();
  forInReturnMulti();
  forInReturnNonNull();
}

////////////////////////////////////////////////////////////////////////////////
// For-in loop directly on a list literal.
////////////////////////////////////////////////////////////////////////////////

/*member: forInDirect:[null]*/
forInDirect() {
  /*iterator: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 3)*/
  /*current: [exact=ArrayIterator]*/
  /*moveNext: [exact=ArrayIterator]*/
  for (var a in [1, 2, 3]) {
    print(a);
  }
}

////////////////////////////////////////////////////////////////////////////////
// Return element from a for-in loop on a list literal.
////////////////////////////////////////////////////////////////////////////////

/*member: forInReturn:[null|subclass=JSInt]*/
forInReturn() {
  /*iterator: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 3)*/
  /*current: [exact=ArrayIterator]*/
  /*moveNext: [exact=ArrayIterator]*/
  for (var a in [1, 2, 3]) {
    // TODO(johnniwinther): We should know the type of [a] here.
    return a;
  }
}

////////////////////////////////////////////////////////////////////////////////
// Return element from a for-in loop on known list type.
////////////////////////////////////////////////////////////////////////////////

/*member: _forInReturn:[null|subclass=Object]*/
_forInReturn(
    /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: null)*/ list) {
  /*iterator: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: null)*/
  /*current: [exact=ArrayIterator]*/
  /*moveNext: [exact=ArrayIterator]*/
  for (var a in list) {
    // TODO(johnniwinther): We should know the type of [a] here.
    return a;
  }
}

/*member: forInReturnMulti:[null]*/
forInReturnMulti() {
  _forInReturn([1, 2]);
  _forInReturn([1, 2, 3]);
}

////////////////////////////////////////////////////////////////////////////////
// Sequentially refine that an element is not null and return it from a for-in
// loop on known list type.
////////////////////////////////////////////////////////////////////////////////

/*member: forInReturnNonNull:[subclass=JSInt]*/
forInReturnNonNull() {
  /*iterator: Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 3)*/
  /*current: [exact=ArrayIterator]*/
  /*moveNext: [exact=ArrayIterator]*/
  for (var a in [1, 2, 3]) {
    // TODO(johnniwinther): We should know the type of [a] here. Even if [a] has
    // type `dynamic`.
    a. /*[null|subclass=JSInt]*/ isEven;
    a. /*[subclass=JSInt]*/ isEven;
    return a;
  }
  return 0;
}
