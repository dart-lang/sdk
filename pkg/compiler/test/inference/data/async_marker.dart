// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  asyncMethod();
  asyncMethodWithReturn();
  asyncStarMethod();
  syncStarMethod();
}

/*member: asyncMethod:[exact=_Future|powerset=0]*/
asyncMethod() async {}

/*member: asyncMethodWithReturn:Union([exact=JSUInt31|powerset=0], [exact=_Future|powerset=0], powerset: 0)*/
asyncMethodWithReturn() async {
  return 0;
}

/*member: asyncStarMethod:[exact=_ControllerStream|powerset=0]*/
asyncStarMethod() async* {}

/*member: syncStarMethod:[exact=_SyncStarIterable|powerset=0]*/
syncStarMethod() sync* {}
