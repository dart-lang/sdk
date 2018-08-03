// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

main() {
  asyncStart();

  // On MacOS you get the decomposed utf8 form of file and directory
  // names from the system. Therefore, we have to check for both here.
  var precomposed = 'æøå';
  var decomposed = new String.fromCharCodes([47, 230, 248, 97, 778]);

  Directory.systemTemp.createTemp('dart_directory_non_ascii').then((tempDir) {
    var nonAsciiDir = new Directory("${tempDir.path}/æøå");
    nonAsciiDir
        .exists()
        .then((e) => Expect.isFalse(e))
        .then((_) => nonAsciiDir.create())
        .then((_) => nonAsciiDir.exists())
        .then((e) => Expect.isTrue(e))
        .then((_) => new Directory("${tempDir.path}/æøå").createTemp('temp'))
        .then((temp) {
          Expect.isTrue(temp.path.contains(precomposed) ||
              temp.path.contains(decomposed));
          return temp.delete();
        })
        .then((_) => tempDir.createTemp('æøå'))
        .then((temp) {
          Expect.isTrue(temp.path.contains(precomposed) ||
              temp.path.contains(decomposed));
          return temp.delete();
        })
        .then((temp) => Expect.isFalse(temp.existsSync()))
        .then((_) => tempDir.delete(recursive: true))
        .then((_) {
          Expect.isFalse(nonAsciiDir.existsSync());
          asyncEnd();
        });
  });
}
