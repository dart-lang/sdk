// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

main() {
  asyncStart();

  bool waitedForCancel = false;

  var controller = new StreamController(
      onCancel: () => new Future(() => waitedForCancel = true));
  var sub = controller.stream.take(1).listen((x) {
    Expect.fail("onData should not be called");
  });
  var cancelFuture = sub.cancel();
  Expect.isNotNull(cancelFuture);
  cancelFuture.then((_) {
    Expect.isTrue(waitedForCancel);
    asyncEnd();
  });
}
