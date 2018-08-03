// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library load_library;

import 'dart:mirrors';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

import 'other_library.dart' deferred as other;

main() {
  var ms = currentMirrorSystem();
  LibraryMirror thisLibrary = ms.findLibrary(#load_library);
  var dep =
      thisLibrary.libraryDependencies.singleWhere((d) => d.prefix == #other);
  Expect.isNull(dep.targetLibrary, "should not be loaded yet");

  asyncStart();
  dep.loadLibrary().then((_) {
    asyncEnd();
    Expect.isNotNull(dep.targetLibrary);
    Expect.equals(#test.other_library, dep.targetLibrary.simpleName);
    Expect.equals(42, other.topLevelMethod());
  });
}
