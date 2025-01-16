// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate' show SendPort;

import 'deferred_in_isolate_lib.dart' deferred as lib;

void main(List<String> args, Object? msg) {
  assert(args.length == 1);
  var expectedMsg = args[0];
  var replyPort = msg as SendPort;

  replyPort.send(true); // Tell test that isolate has started.

  lib.loadLibrary().then((_) {
    var obj = lib.DeferredObj(expectedMsg);
    replyPort.send("$obj");
  });
}
