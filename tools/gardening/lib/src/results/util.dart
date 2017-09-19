// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class PathHelper {
  static String testPyPath() => "tools/test.py";
}

String getSuiteNameForTest(String name) {
  var reg = new RegExp(r"^(.*?)\/.*$");
  var match = reg.firstMatch(name);
  if (match == null) {
    return null;
  }
  return match.group(1);
}

String getQualifiedNameForTest(String name) {
  if (name.startsWith("cc/")) {
    return name;
  }
  return name.substring(name.indexOf("/") + 1);
}
