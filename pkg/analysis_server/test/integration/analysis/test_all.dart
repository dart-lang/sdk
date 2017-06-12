// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_options_test.dart' as analysis_options_test;
import 'error_test.dart' as error_test;
import 'get_errors_nonStandard_sdk.dart' as get_errors_nonStandard_sdk;
import 'get_errors_test.dart' as get_errors_test;
import 'get_hover_test.dart' as get_hover_test;
import 'get_library_dependencies_test.dart' as get_library_dependencies_test;
import 'get_navigation_test.dart' as get_navigation_test;
import 'get_reachable_sources_test.dart' as get_reachable_sources_test;
import 'highlights_test.dart' as highlights_test;
import 'highlights_test2.dart' as highlights_test2;
import 'lint_test.dart' as lint_test;
import 'navigation_test.dart' as navigation_test;
import 'occurrences_test.dart' as occurrences_test;
import 'outline_test.dart' as outline_test;
import 'overrides_test.dart' as overrides_test;
import 'package_root_test.dart' as package_root_test;
import 'reanalyze_concurrent_test.dart' as reanalyze_concurrent_test;
import 'reanalyze_test.dart' as reanalyze_test;
import 'set_analysis_roots_test.dart' as set_analysis_roots_test;
import 'set_general_subscriptions_test.dart' as set_general_subscriptions_test;
import 'set_priority_files_test.dart' as set_priority_files_test;
import 'set_subscriptions_test.dart' as set_subscriptions_test;
import 'update_content_list_test.dart' as update_content_list_test;
import 'update_content_test.dart' as update_content_test;
import 'update_options_test.dart' as update_options_test;

/**
 * Utility for manually running all integration tests.
 */
main() {
  defineReflectiveSuite(() {
    analysis_options_test.main();
    error_test.main();
    get_errors_test.main();
    get_errors_nonStandard_sdk.main();
    get_library_dependencies_test.main();
    get_hover_test.main();
    get_navigation_test.main();
    get_reachable_sources_test.main();
    highlights_test.main();
    highlights_test2.main();
    lint_test.main();
    navigation_test.main();
    occurrences_test.main();
    outline_test.main();
    overrides_test.main();
    package_root_test.main();
    reanalyze_concurrent_test.main();
    reanalyze_test.main();
    set_analysis_roots_test.main();
    set_general_subscriptions_test.main();
    set_priority_files_test.main();
    set_subscriptions_test.main();
    update_content_test.main();
    update_content_list_test.main();
    update_options_test.main();
  }, name: 'analysis');
}
