// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library library_enumeration_deferred_loading;

import 'dart:mirrors';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';

import 'other_library.dart' deferred as other;

main() {
  var ms = currentMirrorSystem();
  Expect.throws(() => ms.findLibrary(#test.other_library), (e) => true,
      "should not be loaded yet");

  asyncStart();
  other.loadLibrary().then((_) {
    asyncEnd();
    LibraryMirror otherMirror = ms.findLibrary(#test.other_library);
    Expect.isNotNull(otherMirror);
    Expect.equals(#test.other_library, otherMirror.simpleName);
    Expect.equals(42, other.topLevelMethod());
  });
}
