// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Macro tokens that are expanded in pipeline jobs and test messages. */
class Macros {
  // Parts of the test file path.
  static const String fullFilePath = '<FULLFILEPATH>';
  static const String filename = '<FILENAME>';
  static const String filenameNoExtension = '<FILENAMENOEXT>';
  static const String directory = '<DIRECTORY>';

  // A verson of the directory that is flattened to be like a filename,
  // by replacing path separators with underscores and removing special
  // characters.
  static const String flattenedDirectory = '<FLATDIR>';

  // Test result message components. These can be used to specify a
  // format for the test result or listing messages. Note that if an
  // actual value is empty, the replacement string will be empty, but if
  // the value is non-empty, the replacement string will be the value
  // followed by space. Thus:
  //
  //   '<MESSAGE><STACK>'
  //
  // would be expanded to an empty string if neither of these are set, but
  // if both are set, they will be separated by a space (and there will be
  // a trailing space). If only <STACK> is set, then this will expand to
  // the stack trace with no leading space but with a trailing space.
  static const String testTime = '<TIME>';
  static const String testfile = '<FILENAME>';
  static const String testGroup = '<GROUPNAME>';
  static const String testDescription = '<TESTNAME>';
  static const String testMessage = '<MESSAGE>';
  static const String testStacktrace = '<STACK>';
}
