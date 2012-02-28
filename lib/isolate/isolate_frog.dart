// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Dart isolate's API and implementation for frog.
#library("dart:isolate");

#import("../uri/uri.dart");
#source("isolate_api.dart");
#source("frog/compiler_hooks.dart");
#source("frog/isolateimpl.dart");
#source("frog/ports.dart");
#source("frog/messages.dart");
#native("frog/natives.js");

/** Default factory for [Isolate2]. */
class _IsolateFactory {

  factory Isolate2.fromCode(Function topLevelFunction) {
    final name = _IsolateNatives._getJSFunctionName(topLevelFunction);
    if (name == null) {
      throw new UnsupportedOperationException(
          "only top-level functions can be spawned.");
    }
    return new _Isolate2Impl(_IsolateNatives._spawn2(name, null, false));
  }

  factory Isolate2.fromUri(String uri) {
    return new _Isolate2Impl(_IsolateNatives._spawn2(null, uri, false));
  }
}
