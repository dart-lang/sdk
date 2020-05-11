// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library interactive_test;

import 'dart:async';
import 'dart:html';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'utils.dart';

Future testGetCurrentPosition() async {
  var position = await window.navigator.geolocation.getCurrentPosition();
  Expect.isNotNull(position.coords.latitude);
  Expect.isNotNull(position.coords.longitude);
  Expect.isNotNull(position.coords.accuracy);
}

Future testWatchPosition() async {
  var position = await window.navigator.geolocation.watchPosition().first;
  Expect.isNotNull(position.coords.latitude);
  Expect.isNotNull(position.coords.longitude);
  Expect.isNotNull(position.coords.accuracy);
}

main() {
  asyncTest(() async {
    await testGetCurrentPosition();
    await testWatchPosition();
  });
}
