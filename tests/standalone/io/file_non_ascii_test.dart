// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

main() {
  var port = new ReceivePort();
  Directory scriptDir = new File(new Options().script).directorySync();
  var f = new File("${scriptDir.path}/æøå/æøå.dat");
  // On MacOS you get the decomposed utf8 form of file and directory
  // names from the system. Therefore, we have to check for both here.
  var precomposed = 'æøå';
  var decomposed = new String.fromCharCodes([47, 230, 248, 97, 778]);
  f.exists().then((e) {
    Expect.isTrue(e);
    f.create().then((_) {
      f.directory().then((d) {
        Expect.isTrue(d.path.endsWith(precomposed) ||
                      d.path.endsWith(decomposed));
        f.length().then((l) {
          Expect.equals(6, l);
          f.lastModified().then((_) {
            f.fullPath().then((p) {
              Expect.isTrue(p.endsWith('${precomposed}.dat') ||
                            p.endsWith('${decomposed}.dat'));
              f.readAsText().then((contents) {
                Expect.equals(precomposed, contents);
                port.close();
              });
            });
          });
        });
      });
    });
  });
}
