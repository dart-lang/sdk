// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';

/*member: main:[null]*/
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

/*member: _method1a:[null]*/
_method1a(/*[null|subclass=JSInt]*/ o) {}

/*member: awaitOfFuture:[exact=_Future]*/
awaitOfFuture() async {
  var future = Future.value(0);
  _method1a(await future);
}

/*member: _method1b:[null]*/
_method1b(/*[null|subclass=JSInt]*/ o) {}

/*member: awaitOfFutureWithLocal:[exact=_Future]*/
awaitOfFutureWithLocal() async {
  var future = Future.value(0);
  var local = await future;
  _method1b(local);
}

////////////////////////////////////////////////////////////////////////////////
// Await of int.
////////////////////////////////////////////////////////////////////////////////

/*member: _method2a:[null]*/
_method2a(/*[null|subclass=JSInt]*/ o) {}

/*member: awaitOfInt:[exact=_Future]*/
awaitOfInt() async {
  _method2a(await 0);
}

/*member: _method2b:[null]*/
_method2b(/*[null|subclass=JSInt]*/ o) {}

/*member: awaitOfIntWithLocal:[exact=_Future]*/
awaitOfIntWithLocal() async {
  var local = await 0;
  _method2b(local);
}

////////////////////////////////////////////////////////////////////////////////
// Await for of Stream.fromIterable.
////////////////////////////////////////////////////////////////////////////////

/*member: _method3:[null]*/
_method3(
    /*Container([exact=JSExtendableArray], element: [exact=JSUInt31], length: 1)*/
    o) {}

/*member: _method4:[null]*/
_method4(/*[null|subclass=JSInt]*/ o) {}

/*member: awaitForOfStream:[exact=_Future]*/
awaitForOfStream() async {
  var list = [0];
  _method3(list);
  var stream = Stream.fromIterable(list);
  /*current: [exact=_StreamIterator]*/
  /*moveNext: [exact=_StreamIterator]*/
  await for (var local in stream) {
    _method4(local);
  }
}
