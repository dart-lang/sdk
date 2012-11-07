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
 * start of your set sequence. Your group descriptions MUST NOT contain spaces.
 */
#library('unittest');

#import('unittest.dart', prefix: 'unittest_file');
#import('html_config.dart', prefix: 'htmlconfig');
#import('dart:html');

class HtmlIndividualConfiguration extends htmlconfig.HtmlConfiguration {

  String _noSuchTest = ''; 
  HtmlIndividualConfiguration(isLayoutTest): super(isLayoutTest);

  void onStart() {
    var testName = window.location.hash;
    if (testName != '') {
      try {
        testName = testName.substring(1); // cut off the #
        unittest_file.filterTests('^$testName');
      } catch (e) {
        print('tried to match "$testName"');
        for (TestCase c in unittest_file.testCases)
          print('test case ${c.description}');
        print('NO_SUCH_TEST');
        exit(1);
      }
    }
    super.onStart();
  }
}

void useHtmlIndividualConfiguration([bool isLayoutTest = false]) {
  unittest_file.configure(new HtmlIndividualConfiguration(isLayoutTest));
}
