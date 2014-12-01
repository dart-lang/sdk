// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'issue_1751477_lib1.dart' deferred as lib1;
import 'issue_1751477_lib2.dart' deferred as lib2;
import 'issue_1751477_lib3.dart' deferred as lib3;
import 'issue_1751477_lib4.dart' deferred as lib4;
import 'issue_1751477_lib5.dart' deferred as lib5;
import 'issue_1751477_lib6.dart' deferred as lib6;
import 'issue_1751477_lib7.dart' deferred as lib7;
import 'issue_1751477_lib8.dart' deferred as lib8;
import 'issue_1751477_lib9.dart' deferred as lib9;

main() {
  lib1.loadLibrary().then((_) {
    lib2.loadLibrary().then((_) {
      lib3.loadLibrary().then((_) {
        lib4.loadLibrary().then((_) {
          lib5.loadLibrary().then((_) {
            lib6.loadLibrary().then((_) {
              lib7.loadLibrary().then((_) {
                lib8.loadLibrary().then((_) {
                  lib9.loadLibrary().then((_) {
                  });
                });
              });
            });
          });
        });
      });
    });
  });
}
