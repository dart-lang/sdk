// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void main() {
  if (Platform.isLinux) {
    asyncStart();
    var selfExe = new Link('/proc/self/exe');
    Expect.isTrue(selfExe.targetSync().length > 0);
    selfExe.target().then((target) {
      Expect.isTrue(target.length > 0);
      asyncEnd();
    });
  }
}
