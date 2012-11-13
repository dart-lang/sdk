// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

main() {
  var port = new ReceivePort();
  Directory scriptDir = new File(new Options().script).directorySync();
  var f = new File("${scriptDir.path}/æøå/æøå.dat");
  f.exists().then((e) {
    Expect.isTrue(e);
    f.create().then((_) {
      f.directory().then((d) {
        Expect.isTrue(d.path.endsWith('æøå'));
        f.length().then((l) {
          Expect.equals(6, l);
          f.lastModified().then((_) {
            f.fullPath().then((p) {
              Expect.isTrue(p.endsWith('æøå.dat'));
              f.readAsText().then((contents) {
                Expect.equals('æøå', contents);
                port.close();
              });
            });
          });
        });
      });
    });
  });
}
