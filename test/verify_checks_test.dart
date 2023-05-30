// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../tool/checks/driver.dart';

main() {
  group('custom checks', () {
    var checkNames = customChecks.map((c) => c.name).join(', ');
    test(checkNames, () async {
      var failedChecks = await runChecks();
      expect(failedChecks, isEmpty);
    });
  }, timeout: Timeout(Duration(minutes: 2)));
}
