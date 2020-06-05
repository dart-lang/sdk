// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';

/*member: main:[null]*/
main() {
  awaitOfFuture();
  awaitOfInt();
  awaitForOfStream();
}

////////////////////////////////////////////////////////////////////////////////
// Await of Future.value.
////////////////////////////////////////////////////////////////////////////////

/*member: _method1:[null]*/
_method1(/*[null|subclass=JSInt]*/ o) {}

/*member: awaitOfFuture:[exact=_Future]*/
awaitOfFuture() async {
  var future = new Future.value(0);
  var local = await future;
  _method1(local);
}

////////////////////////////////////////////////////////////////////////////////
// Await of int.
////////////////////////////////////////////////////////////////////////////////

/*member: _method2:[null]*/
_method2(/*[null|subclass=JSInt]*/ o) {}

/*member: awaitOfInt:[exact=_Future]*/
awaitOfInt() async {
  var local = await 0;
  _method2(local);
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
  var stream = new Stream.fromIterable(list);
  /*current: [exact=_StreamIterator]*/
  /*moveNext: [exact=_StreamIterator]*/
  await for (var local in stream) {
    _method4(local);
  }
}
