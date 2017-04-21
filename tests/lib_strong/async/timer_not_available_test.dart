// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library timerNotAvailable;

import 'package:expect/expect.dart';
import 'dart:async';

main() {
  final ms = const Duration(milliseconds: 1);
  bool failed = false;
  try {
    new Timer(ms * 5, () {});
  } on UnsupportedError catch (e) {
    failed = true;
  }
  Expect.isTrue(failed);
  failed = false;
  try {
    var t = new Timer.periodic(ms * 10, (_) {});
    t.cancel();
  } on UnsupportedError catch (e) {
    failed = true;
  }
  Expect.isTrue(failed);
}
