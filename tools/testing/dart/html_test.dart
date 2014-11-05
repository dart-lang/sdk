// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Classes and methods for running HTML tests.
 *
 * HTML tests are valid HTML files whose names end in _htmltest.html, and that
 * contain annotations specifying the scripts in the test and the
 * messages the test should post to its window, in order to pass.
 */
library html_test;

import "dart:convert";
import "dart:io";

import "test_suite.dart";
import "utils.dart";

RegExp htmlAnnotation =
    new RegExp("START_HTML_DART_TEST([\\s\\S]*?)END_HTML_DART_TEST");

HtmlTestInformation getInformation(String filename) {
  if (!filename.endsWith("_htmltest.html")) {
    DebugLogger.warning("File $filename is not an HTML test."
        " Should end in _htmltest.html.");
    return null;
  }
  String contents = new File(filename).readAsStringSync();
  var match = htmlAnnotation.firstMatch(contents);
  if (match == null) return null;
  var annotation = JSON.decode(match[1]);
  if (annotation is! Map || annotation['expectedMessages'] is! List ||
      annotation['scripts'] is! List) {
    DebugLogger.warning("File $filename does not have expected annotation."
        " Should have {'scripts':[...], 'expectedMessages':[...]}");
    return null;
  }
  return new HtmlTestInformation(new Path(filename),
                                 annotation['expectedMessages'],
                                 annotation['scripts']);
}

String getContents(HtmlTestInformation info) {
  String contents = new File(info.filePath.toNativePath()).readAsStringSync();
  return contents.replaceFirst(htmlAnnotation, '');
}