// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

final NOT_HERE = "notHere";
final NOT_HERE_URI = "file:///no/such/file/";

class Foo {}

void main([args, port]) {
  if (port != null) {
    testPackageRoot(port);
    return;
  }
  var p = new RawReceivePort();
  p.handler = (msg) {
    p.close();
    // Cannot use the expect package here because the spawned isolate
    // would not be able to handle it.
    if (msg is! List) {
      throw "Bad response from child isolate: $msg";
    }
    if (msg.length != 2) {
      throw "Length should be 2: ${msg.length}\nmsg: $msg";
    }
    if (msg[0] != NOT_HERE) {
      throw "Key should be $NOT_HERE: ${msg[0]}";
    }
    if (msg[1] != NOT_HERE_URI) {
      throw "Value should be $NOT_HERE_URI: ${msg[1]}";
    }
  };
  Isolate.spawnUri(Platform.script,
                   [],
                   p.sendPort,
                   packageMap: {
                     NOT_HERE: Uri.parse(NOT_HERE_URI)
                   });
}

testPackageRoot(port) async {
  var packageMap = await Isolate.packageMap;
  var packageMapEntries = [];
  if (packageMap is! Map) {
    port.send("packageMap is not a Map: ${packageMap.runtimeType}");
    return;
  }
  var ok = true;
  packageMap.forEach((k, v) {
    if (ok && (k is! String)) {
      port.send("Key $k is not a String: ${k.runtimeType}");
      ok = false;
    }
    packageMapEntries.add(k);
    if (ok && (v is! Uri)) {
      port.send("Value $v is not a Uri: ${v.runtimeType}");
      ok = false;
    }
    packageMapEntries.add(v.toString());
  });
  if (ok) {
    port.send(packageMapEntries);
  }
}
