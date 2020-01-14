// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import "package:async_helper/async_helper.dart";
import 'package:expect/expect.dart';

import 'event_helper.dart';

void main() {
  asyncStart();
  var transformer =
      new StreamTransformer<int, String>.fromBind((s) => s.map((v) => '$v'));
  var controller = new StreamController<int>(sync: true);
  Events expected = new Events.fromIterable(['1', '2']);
  Events input = new Events.fromIterable([1, 2]);
  Events actual = new Events.capture(controller.stream.transform(transformer));
  actual.onDone(() {
    Expect.listEquals(expected.events, actual.events);
    asyncEnd();
  });
  input.replay(controller);
}
