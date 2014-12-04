// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library browser_test;

import 'path.dart';

String getHtmlContents(String title,
                       String scriptType,
                       Path sourceScript) {
  return """
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="dart.unittest" content="full-stack-traces">
  <title> Test $title </title>
  <style>
     .unittest-table { font-family:monospace; border:1px; }
     .unittest-pass { background: #6b3;}
     .unittest-fail { background: #d55;}
     .unittest-error { background: #a11;}
  </style>
</head>
<body>
  <h1> Running $title </h1>
  <script type="text/javascript"
          src="/root_dart/tools/testing/dart/test_controller.js">
  </script>
  <script type="$scriptType" src="$sourceScript"
          onerror="scriptTagOnErrorCallback(null)"
          defer>
  </script>
  <script type="text/javascript"
          src="/root_dart/pkg/browser/lib/dart.js"></script>
</body>
</html>""";
}

String dartTestWrapper(String libraryPathComponent) {
  return """
import '$libraryPathComponent' as test;

main() {
  print("dart-calling-main");
  test.main();
  print("dart-main-done");
}
""";
}
