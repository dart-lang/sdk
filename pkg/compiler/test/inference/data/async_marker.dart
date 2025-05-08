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

/*member: asyncMethod:[exact=_Future|powerset={N}{O}{N}]*/
asyncMethod() async {}

/*member: asyncMethodWithReturn:Union([exact=JSUInt31|powerset={I}{O}{N}], [exact=_Future|powerset={N}{O}{N}], powerset: {IN}{O}{N})*/
asyncMethodWithReturn() async {
  return 0;
}

/*member: asyncStarMethod:[exact=_ControllerStream|powerset={N}{O}{N}]*/
asyncStarMethod() async* {}

/*member: syncStarMethod:[exact=_SyncStarIterable|powerset={N}{O}{N}]*/
syncStarMethod() sync* {}
