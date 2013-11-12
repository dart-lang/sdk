// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:unittest/unittest.dart';

import '../lib/src/sdk.dart' as sdk;
import '../lib/src/version.dart';

main() {
  group("parseVersion()", () {
    test("parses a release-style version", () {
      expect(sdk.parseVersion("0.1.2.0_r17645"),
          equals(new Version.parse("0.1.2+0.r17645")));
    });

    test("parses a dev-only style version", () {
      // The "version" file generated on developer builds is a little funky and
      // we need to make sure we don't choke on it.
      expect(sdk.parseVersion("0.1.2.0_r16279_bobross"),
          equals(new Version.parse("0.1.2+0.r16279.bobross")));
    });
  });
}
