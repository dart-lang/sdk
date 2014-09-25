// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library test.analysis;

import 'package:unittest/unittest.dart';

import 'get_errors_test.dart' as get_errors_test;
import 'get_hover_test.dart' as get_hover_test;
import 'notification_errors_test.dart' as notification_errors_test;
import 'notification_highlights_test.dart' as notification_highlights_test;
import 'notification_navigation_test.dart' as notification_navigation_test;
import 'notification_occurrences_test.dart' as notification_occurrences_test;
import 'notification_outline_test.dart' as notification_outline_test;
import 'notification_overrides_test.dart' as notification_overrides_test;

/**
 * Utility for manually running all tests.
 */
main() {
  groupSep = ' | ';
  group('search', () {
    get_errors_test.main();
    get_hover_test.main();
    notification_errors_test.main();
    notification_highlights_test.main();
    notification_navigation_test.main();
    notification_occurrences_test.main();
    notification_outline_test.main();
    notification_overrides_test.main();
  });
}
