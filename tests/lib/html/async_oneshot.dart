// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/minitest.dart';

main(message, replyTo) {
  var command = message.first;
  expect(command, 'START');
  new Timer(const Duration(milliseconds: 10), () {
    replyTo.send('DONE');
  });
}
