// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/*member: main:[null|powerset={null}]*/
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

/*member: _method1a:[null|powerset={null}]*/
_method1a(/*[subclass=JSInt|powerset={I}{O}]*/ o) {}

/*member: awaitOfFuture:[exact=_Future|powerset={N}{O}]*/
awaitOfFuture() async {
  var future = Future.value(0);
  _method1a(await future);
}

/*member: _method1b:[null|powerset={null}]*/
_method1b(/*[subclass=JSInt|powerset={I}{O}]*/ o) {}

/*member: awaitOfFutureWithLocal:[exact=_Future|powerset={N}{O}]*/
awaitOfFutureWithLocal() async {
  var future = Future.value(0);
  var local = await future;
  _method1b(local);
}

////////////////////////////////////////////////////////////////////////////////
// Await of int.
////////////////////////////////////////////////////////////////////////////////

/*member: _method2a:[null|powerset={null}]*/
_method2a(/*[subclass=JSInt|powerset={I}{O}]*/ o) {}

/*member: awaitOfInt:[exact=_Future|powerset={N}{O}]*/
awaitOfInt() async {
  _method2a(await 0);
}

/*member: _method2b:[null|powerset={null}]*/
_method2b(/*[subclass=JSInt|powerset={I}{O}]*/ o) {}

/*member: awaitOfIntWithLocal:[exact=_Future|powerset={N}{O}]*/
awaitOfIntWithLocal() async {
  var local = await 0;
  _method2b(local);
}

////////////////////////////////////////////////////////////////////////////////
// Await for of Stream.fromIterable.
////////////////////////////////////////////////////////////////////////////////

/*member: _method3:[null|powerset={null}]*/
_method3(
  /*Container([exact=JSExtendableArray|powerset={I}{G}], element: [exact=JSUInt31|powerset={I}{O}], length: 1, powerset: {I}{G})*/
  o,
) {}

/*member: _method4:[null|powerset={null}]*/
_method4(/*[subclass=JSInt|powerset={I}{O}]*/ o) {}

/*member: awaitForOfStream:[exact=_Future|powerset={N}{O}]*/
awaitForOfStream() async {
  var list = [0];
  _method3(list);
  var stream = Stream.fromIterable(list);
  /*current: [exact=_StreamIterator|powerset={N}{O}]*/
  /*moveNext: [exact=_StreamIterator|powerset={N}{O}]*/
  await for (var local in stream) {
    _method4(local);
  }
}
