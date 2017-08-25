// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'get_errors_test.dart' as get_errors_test;
import 'get_hover_test.dart' as get_hover_test;
import 'get_navigation_test.dart' as get_navigation_test;
import 'notification_analysis_options_test.dart'
    as notification_analysis_options_test;
import 'notification_analyzedFiles_test.dart'
    as notification_analyzedFiles_test;
import 'notification_closingLabels_test.dart'
    as notification_closingLabels_test;
import 'notification_errors_test.dart' as notification_errors_test;
import 'notification_highlights_test.dart' as notification_highlights_test;
import 'notification_highlights_test2.dart' as notification_highlights_test2;
import 'notification_implemented_test.dart' as notification_implemented_test;
import 'notification_navigation_test.dart' as notification_navigation_test;
import 'notification_occurrences_test.dart' as notification_occurrences_test;
import 'notification_outline_test.dart' as notification_outline_test;
import 'notification_overrides_test.dart' as notification_overrides_test;
import 'reanalyze_test.dart' as reanalyze_test;
import 'set_priority_files_test.dart' as set_priority_files_test;
import 'update_content_test.dart' as update_content_test;

/**
 * Utility for manually running all tests.
 */
main() {
  defineReflectiveSuite(() {
    get_errors_test.main();
    get_hover_test.main();
    get_navigation_test.main();
    notification_analysis_options_test.main();
    notification_analyzedFiles_test.main();
    notification_closingLabels_test.main();
    notification_errors_test.main();
    notification_highlights_test.main();
    notification_highlights_test2.main();
    notification_implemented_test.main();
    notification_navigation_test.main();
    notification_occurrences_test.main();
    notification_outline_test.main();
    notification_overrides_test.main();
    reanalyze_test.main();
    set_priority_files_test.main();
    update_content_test.main();
  }, name: 'analysis');
}
