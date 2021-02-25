// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bazel_changes_test.dart' as bazel_changes;
import 'get_errors_test.dart' as get_errors;
import 'get_hover_test.dart' as get_hover;
import 'get_navigation_test.dart' as get_navigation;
import 'get_signature_test.dart' as get_signature_information;
import 'notification_analysis_options_test.dart'
    as notification_analysis_options;
import 'notification_analyzed_files_test.dart' as notification_analyzed_files;
import 'notification_closing_labels_test.dart' as notification_closing_labels;
import 'notification_errors_test.dart' as notification_errors;
import 'notification_folding_test.dart' as notification_folding;
import 'notification_highlights2_test.dart' as notification_highlights2;
import 'notification_implemented_test.dart' as notification_implemented;
import 'notification_navigation_test.dart' as notification_navigation;
import 'notification_occurrences_test.dart' as notification_occurrences;
import 'notification_outline_test.dart' as notification_outline;
import 'notification_overrides_test.dart' as notification_overrides;
import 'reanalyze_test.dart' as reanalyze;
import 'set_priority_files_test.dart' as set_priority_files;
import 'update_content_test.dart' as update_content;

void main() {
  defineReflectiveSuite(() {
    bazel_changes.main();
    get_errors.main();
    get_hover.main();
    get_navigation.main();
    get_signature_information.main();
    notification_analysis_options.main();
    notification_analyzed_files.main();
    notification_closing_labels.main();
    notification_folding.main();
    notification_errors.main();
    notification_highlights2.main();
    notification_implemented.main();
    notification_navigation.main();
    notification_occurrences.main();
    notification_outline.main();
    notification_overrides.main();
    reanalyze.main();
    set_priority_files.main();
    update_content.main();
  }, name: 'analysis');
}
