// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9
import 'dart:async';

import 'package:expect/expect.dart';

main() {
  // Single-cast async.
  var controller = StreamController();
  Expect.throwsTypeError(() {
    controller.addError(null);
  });

  Expect.throwsTypeError(() {
    controller.sink.addError(null);
  });

  // Single-cast sync.
  controller = StreamController(sync: true);
  Expect.throwsTypeError(() {
    controller.addError(null);
  });

  Expect.throwsTypeError(() {
    controller.sink.addError(null);
  });

  // Broadcast async.
  controller = StreamController.broadcast();
  Expect.throwsTypeError(() {
    controller.addError(null);
  });

  Expect.throwsTypeError(() {
    controller.sink.addError(null);
  });

  // Broadcast sync.
  controller = StreamController.broadcast(sync: true);
  Expect.throwsTypeError(() {
    controller.addError(null);
  });

  Expect.throwsTypeError(() {
    controller.sink.addError(null);
  });
}
