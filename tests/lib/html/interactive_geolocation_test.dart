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
  var coords = position.coords!;
  Expect.isNotNull(coords.latitude);
  Expect.isNotNull(coords.longitude);
  Expect.isNotNull(coords.accuracy);
}

Future testWatchPosition() async {
  var position = await window.navigator.geolocation.watchPosition().first;
  var coords = position.coords!;
  Expect.isNotNull(coords.latitude);
  Expect.isNotNull(coords.longitude);
  Expect.isNotNull(coords.accuracy);
}

main() {
  asyncTest(() async {
    await testGetCurrentPosition();
    await testWatchPosition();
  });
}
