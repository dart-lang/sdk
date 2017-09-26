// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String BUILDER_PROJECT = "chromium";
const String CQ_PROJECT = "dart";

/// [PathHelper] is a utility class holding information about static paths.
class PathHelper {
  static String testPyPath() => "tools/test.py";
}

/// Returns the test-suite for [name].
String getSuiteNameForTest(String name) {
  var reg = new RegExp(r"^(.*?)\/.*$");
  var match = reg.firstMatch(name);
  if (match == null) {
    return null;
  }
  return match.group(1);
}

/// Returns the qualified name (what to use in status-files) for a test with
/// [name].
String getQualifiedNameForTest(String name) {
  if (name.startsWith("cc/")) {
    return name;
  }
  return name.substring(name.indexOf("/") + 1);
}
