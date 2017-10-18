// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  asyncMethod();
  asyncMethodWithReturn();
  asyncStarMethod();
  syncStarMethod();
}

/*element: asyncMethod:[exact=_Future]*/
asyncMethod() async {}

/*element: asyncMethodWithReturn:Union of [[exact=JSUInt31], [exact=_Future]]*/
asyncMethodWithReturn() async {
  return 0;
}

/*element: asyncStarMethod:[exact=_ControllerStream]*/
asyncStarMethod() async* {}

/*element: syncStarMethod:[exact=_SyncStarIterable]*/
syncStarMethod() sync* {}
