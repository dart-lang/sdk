// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
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
#library('unittest');

#import('unittest.dart', prefix: 'unittest');
#import('html_config.dart', prefix: 'htmlconfig');
#import('dart:html');

class HtmlIndividualConfiguration extends htmlconfig.HtmlConfiguration {

  String _noSuchTest = ''; 
  HtmlIndividualConfiguration(isLayoutTest): super(isLayoutTest);

  void onStart() {
    var testGroupName = window.location.hash;
    if (testGroupName != '') {
      try {
        testGroupName = testGroupName.substring(1); // cut off the #
        unittest.filterTests('^$testGroupName');
      } catch (e) {
        print('tried to match "$testGroupName"');
        print('NO_SUCH_TEST');
        exit(1);
      }
    }
    super.onStart();
  }
}

void useHtmlIndividualConfiguration([bool isLayoutTest = false]) {
  unittest.configure(new HtmlIndividualConfiguration(isLayoutTest));
}
