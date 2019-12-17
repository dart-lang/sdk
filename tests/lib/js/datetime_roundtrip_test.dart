// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js';
import 'package:expect/expect.dart';

main() {
  var dt = new DateTime.now();
  var jsArray = new JsObject.jsify([dt]);
  var roundTripped = jsArray[0];
  Expect.isTrue(roundTripped is DateTime);
  Expect.equals(dt.millisecondsSinceEpoch, roundTripped.millisecondsSinceEpoch);
}
