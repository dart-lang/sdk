// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

main() {
  var port = new ReceivePort();

  // On MacOS you get the decomposed utf8 form of file and directory
  // names from the system. Therefore, we have to check for both here.
  var precomposed = 'æøå';
  var decomposed = new String.fromCharCodes([47, 230, 248, 97, 778]);

  new Directory('').createTemp().then((tempDir) {
    var nonAsciiDir = new Directory("${tempDir.path}/æøå");
    nonAsciiDir.exists().then((e) {
      Expect.isFalse(e);
      nonAsciiDir.create().then((_) {
        nonAsciiDir.exists().then((e) {
          Expect.isTrue(e);
          new Directory("${tempDir.path}/æøå").createTemp().then((temp) {
            Expect.isTrue(temp.path.contains(precomposed) ||
                          temp.path.contains(decomposed));
            temp.delete().then((_) {
              tempDir.delete(recursive: true).then((_) {
                Expect.isFalse(temp.existsSync());
                Expect.isFalse(nonAsciiDir.existsSync());
                port.close();
              });
            });
          });
        });
      });
    });
  });
}
