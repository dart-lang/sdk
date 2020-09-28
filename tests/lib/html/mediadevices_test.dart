// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

test() async {
  var list = await window.navigator.mediaDevices!.enumerateDevices();
  Expect.isTrue(list is List<dynamic>, "Expected list to be List<dynamic>");
}

void main() {
  asyncStart();
  test().then((_) => asyncEnd());
}
