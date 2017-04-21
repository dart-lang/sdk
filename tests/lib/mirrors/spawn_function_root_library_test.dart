// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;

@MirrorsUsed(targets: "lib")
import 'dart:mirrors';
import 'dart:isolate';
import 'package:expect/expect.dart';

child(SendPort port) {
  LibraryMirror root = currentMirrorSystem().isolate.rootLibrary;
  Expect.isNotNull(root);
  port.send(root.uri.toString());
}

main() {
  var port;
  port = new RawReceivePort((String childRootUri) {
    LibraryMirror root = currentMirrorSystem().isolate.rootLibrary;
    Expect.isNotNull(root);
    Expect.equals(root.uri.toString(), childRootUri);
    port.close();
  });

  Isolate.spawn(child, port.sendPort);
}
