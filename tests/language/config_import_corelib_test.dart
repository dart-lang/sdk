// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'config_import_corelib_general.dart'
    if (dart.library.io) 'config_import_corelib_io.dart'
    if (dart.library.http) 'config_import_corelib_http.dart' as lib;

class SubClassy extends lib.Classy {
  String get superName => super.name;
}

main() {
  var io = const bool.fromEnvironment("dart.library.io");
  var http = const bool.fromEnvironment("dart.library.http");

  var cy = new SubClassy();

  if (io) {
    Expect.isTrue(lib.general());
    Expect.equals("io", lib.name);
    Expect.equals("classy io", cy.name);

    Expect.isTrue(lib.ioSpecific());
    Expect.equals("classy io", cy.ioSpecific());

    Expect.throws(() {
      lib.httpSpecific();
    });
    Expect.throws(() {
      cy.httpSpecific();
    });
  } else if (http) {
    Expect.isTrue(lib.general());
    Expect.equals("http", lib.name);
    Expect.equals("classy http", cy.name);

    Expect.throws(() {
      lib.ioSpecific();
    });
    Expect.throws(() {
      cy.ioSpecific();
    });

    Expect.isTrue(lib.httpSpecific());
    Expect.equals("classy http", cy.httpSpecific());
  } else {
    Expect.isTrue(lib.general());
    Expect.equals("general", lib.name);
    Expect.equals("classy general", cy.name);

    Expect.throws(() {
      lib.ioSpecific();
    });
    Expect.throws(() {
      cy.ioSpecific();
    });

    Expect.throws(() {
      lib.httpSpecific();
    });
    Expect.throws(() {
      cy.httpSpecific();
    });
  }
}
