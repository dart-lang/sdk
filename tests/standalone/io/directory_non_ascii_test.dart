// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

main() {
  var port = new ReceivePort();
  Directory scriptDir = new File(new Options().script).directorySync();
  var d = new Directory("${scriptDir.path}/æøå");
  // On MacOS you get the decomposed utf8 form of file and directory
  // names from the system. Therefore, we have to check for both here.
  var precomposed = 'æøå';
  var decomposed = new String.fromCharCodes([47, 230, 248, 97, 778]);
  d.exists().then((e) {
    Expect.isTrue(e);
    d.create().then((_) {
      new Directory('').createTemp().then((temp) {
        new Directory("${temp.path}/æøå").createTemp().then((temp2) {
          Expect.isTrue(temp2.path.contains(precomposed) ||
                        temp2.path.contains(decomposed));
          temp2.delete().then((_) {
            temp.delete(recursive: true).then((_) {
              port.close();
            });
          });
        });
      });
    });
  });
}
