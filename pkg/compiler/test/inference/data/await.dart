// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/*member: main:[null|powerset=1]*/
main() {
  awaitOfFuture();
  awaitOfFutureWithLocal();
  awaitOfInt();
  awaitOfIntWithLocal();
  awaitForOfStream();
}

////////////////////////////////////////////////////////////////////////////////
// Await of Future.value.
////////////////////////////////////////////////////////////////////////////////

/*member: _method1a:[null|powerset=1]*/
_method1a(/*[subclass=JSInt|powerset=0]*/ o) {}

/*member: awaitOfFuture:[exact=_Future|powerset=0]*/
awaitOfFuture() async {
  var future = Future.value(0);
  _method1a(await future);
}

/*member: _method1b:[null|powerset=1]*/
_method1b(/*[subclass=JSInt|powerset=0]*/ o) {}

/*member: awaitOfFutureWithLocal:[exact=_Future|powerset=0]*/
awaitOfFutureWithLocal() async {
  var future = Future.value(0);
  var local = await future;
  _method1b(local);
}

////////////////////////////////////////////////////////////////////////////////
// Await of int.
////////////////////////////////////////////////////////////////////////////////

/*member: _method2a:[null|powerset=1]*/
_method2a(/*[subclass=JSInt|powerset=0]*/ o) {}

/*member: awaitOfInt:[exact=_Future|powerset=0]*/
awaitOfInt() async {
  _method2a(await 0);
}

/*member: _method2b:[null|powerset=1]*/
_method2b(/*[subclass=JSInt|powerset=0]*/ o) {}

/*member: awaitOfIntWithLocal:[exact=_Future|powerset=0]*/
awaitOfIntWithLocal() async {
  var local = await 0;
  _method2b(local);
}

////////////////////////////////////////////////////////////////////////////////
// Await for of Stream.fromIterable.
////////////////////////////////////////////////////////////////////////////////

/*member: _method3:[null|powerset=1]*/
_method3(
  /*Container([exact=JSExtendableArray|powerset=0], element: [exact=JSUInt31|powerset=0], length: 1, powerset: 0)*/
  o,
) {}

/*member: _method4:[null|powerset=1]*/
_method4(/*[subclass=JSInt|powerset=0]*/ o) {}

/*member: awaitForOfStream:[exact=_Future|powerset=0]*/
awaitForOfStream() async {
  var list = [0];
  _method3(list);
  var stream = Stream.fromIterable(list);
  /*current: [exact=_StreamIterator|powerset=0]*/
  /*moveNext: [exact=_StreamIterator|powerset=0]*/
  await for (var local in stream) {
    _method4(local);
  }
}
