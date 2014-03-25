// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A unit test library for running groups of tests in a browser, instead of the
/// entire test file. This is especially used for large tests files that have
/// many subtests, so we can mark groups as failing at a finer granularity than
/// the entire test file.
///
/// To use, import this file, and call [useHtmlIndividualConfiguration] at the
/// start of your set sequence. Important constraint: your group descriptions
/// MUST NOT contain spaces.
library unittest.html_individual_config;

import 'dart:html';
import 'unittest.dart' as unittest;
import 'html_config.dart' as htmlconfig;

class HtmlIndividualConfiguration extends htmlconfig.HtmlConfiguration {
  HtmlIndividualConfiguration(bool isLayoutTest): super(isLayoutTest);

  void onStart() {
    var search = window.location.search;
    if (search != '') {
      var groups = search.substring(1).split('&')
          .where((p) => p.startsWith('group='))
          .toList();

      if (!groups.isEmpty) {
        if (groups.length > 1) {
          throw new ArgumentError('More than one "group" parameter provided.');
        }

        var testGroupName = groups.single.split('=')[1];
        var startsWith = "$testGroupName${unittest.groupSep}";
        unittest.filterTests((unittest.TestCase tc) =>
            tc.description.startsWith(startsWith));
      }
    }
    super.onStart();
  }
}

void useHtmlIndividualConfiguration([bool isLayoutTest = false]) {
  unittest.unittestConfiguration = isLayoutTest ? _singletonLayout : _singletonNotLayout;
}

final _singletonLayout = new HtmlIndividualConfiguration(true);
final _singletonNotLayout = new HtmlIndividualConfiguration(false);
