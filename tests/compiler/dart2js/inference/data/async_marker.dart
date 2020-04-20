// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  asyncMethod();
  asyncMethodWithReturn();
  asyncStarMethod();
  syncStarMethod();
}

/*member: asyncMethod:[exact=_Future]*/
asyncMethod() async {}

/*member: asyncMethodWithReturn:Union([exact=JSUInt31], [exact=_Future])*/
asyncMethodWithReturn() async {
  return 0;
}

/*member: asyncStarMethod:[exact=_ControllerStream]*/
asyncStarMethod() async* {}

/*member: syncStarMethod:[exact=_SyncStarIterable]*/
syncStarMethod() sync* {}
