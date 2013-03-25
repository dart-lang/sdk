// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A unit test library for running groups of tests in a browser, instead of the
 * entire test file. This is especially used for large tests files that have
 * many subtests, so we can mark groups as failing at a finer granularity than
 * the entire test file.
 *
 * To use, import this file, and call [useHtmlIndividualConfiguration] at the
 * start of your set sequence. Important constraint: your group descriptions
 * MUST NOT contain spaces.
 */
library unittest_html_individual_config;

import 'dart:html';
import 'unittest.dart' as unittest;
import 'html_config.dart' as htmlconfig;

class HtmlIndividualConfiguration extends htmlconfig.HtmlConfiguration {

  String _noSuchTest = '';
  HtmlIndividualConfiguration(isLayoutTest): super(isLayoutTest);

  void onStart() {
    var search = window.location.search;
    if (search != '') {
      try {
        for (var parameter in search.substring(1).split('&')) {
          if (parameter.startsWith('group=')) {
            var testGroupName = parameter.split('=')[1];
            unittest.filterTests('^$testGroupName${unittest.groupSep}');
          }
        }
      } catch (e) {
        print('tried to match "$testGroupName"');
        print('NO_SUCH_TEST');
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
