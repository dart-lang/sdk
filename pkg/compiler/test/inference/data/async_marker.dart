// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  asyncMethod();
  asyncMethodWithReturn();
  asyncStarMethod();
  syncStarMethod();
}

/*member: asyncMethod:[exact=_Future|powerset={N}]*/
asyncMethod() async {}

/*member: asyncMethodWithReturn:Union([exact=JSUInt31|powerset={I}], [exact=_Future|powerset={N}], powerset: {IN})*/
asyncMethodWithReturn() async {
  return 0;
}

/*member: asyncStarMethod:[exact=_ControllerStream|powerset={N}]*/
asyncStarMethod() async* {}

/*member: syncStarMethod:[exact=_SyncStarIterable|powerset={N}]*/
syncStarMethod() sync* {}
