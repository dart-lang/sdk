// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library find_default_locale_browser_test;

import '../lib/intl.dart';
import '../lib/intl_standalone.dart';
import '../../../pkg/unittest/lib/unittest.dart';

main() {
  test("Find system locale standalone", () {
    // TODO (alanknight): This only verifies that we found some locale. We
    // should find a way to force the system locale before the test is run
    // and then verify that it's actually the correct value.
    Intl.systemLocale = "xx_YY";
    var callback = expectAsync1(verifyLocale);
    findSystemLocale().then(callback);
    });
}

verifyLocale(_) {
  expect(Intl.systemLocale, isNot(equals("xx_YY")));
  var pattern = new RegExp(r"\w\w_[A-Z0-9]+");
  var match = pattern.hasMatch(Intl.systemLocale);
  expect(match, isTrue);
}
