// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library foo;

@MirrorsUsed(targets: const ["foo", "bar"])
import 'dart:mirrors';
import 'typedef_library.dart' deferred as def;

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

main() {
  asyncStart();
  def.loadLibrary().then((_) {
    var barLibrary = currentMirrorSystem().findLibrary(new Symbol("bar"));
    var gTypedef = barLibrary.declarations[new Symbol("G")];
    Expect.equals("G", MirrorSystem.getName(gTypedef.simpleName));
    asyncEnd();
  });
}
